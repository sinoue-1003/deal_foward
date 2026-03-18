class GmailImportService
  GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1/users/me"
  EXCLUDED_DOMAINS = %w[
    gmail.com yahoo.co.jp yahoo.com outlook.com hotmail.com
    icloud.com me.com mac.com live.com msn.com
    googlemail.com protonmail.com
  ].freeze
  # Max emails fetched per domain when importing content
  MAX_EMAILS_PER_DOMAIN = 20

  class GmailError < StandardError; end

  # Returns domain-grouped preview data (including email_count per domain).
  # Falls back to demo data when no access_token is available.
  def self.preview(access_token:, max_messages: 100)
    return demo_preview_data if access_token.blank?

    message_ids = fetch_message_list(access_token, max_messages)
    return demo_preview_data if message_ids.empty?

    emails = extract_emails_from_messages(access_token, message_ids)
    groups = group_by_domain(emails)

    # Annotate each group with an estimated email count
    groups.map do |g|
      count = count_emails_for_domain(access_token, g[:domain])
      g.merge(email_count: count)
    end
  rescue GmailError
    demo_preview_data
  end

  # Creates Company + Contact records from selected domain data.
  # Returns { companies_created:, contacts_created:, contact_skipped: }
  def self.import(selected_domains:)
    companies_created = 0
    contacts_created  = 0
    contact_skipped   = 0

    selected_domains.each do |domain_data|
      domain       = domain_data["domain"]
      company_name = domain_data["company_name"].presence || domain_to_company_name(domain)
      contacts     = domain_data["contacts"] || []

      company = Company.find_or_initialize_by(website: domain)
      if company.new_record?
        company.name   = company_name
        company.source = "gmail"
        company.save!
        companies_created += 1
      end

      contacts.each do |c|
        email = c["email"].to_s.strip.downcase
        next if email.blank?

        contact = Contact.find_or_initialize_by(email: email)
        if contact.new_record?
          contact.name           = c["name"].presence || email_to_name(email)
          contact.company        = company
          contact.source_channel = "gmail"
          contact.save!
          contacts_created += 1
        else
          contact_skipped += 1
        end
      end
    end

    { companies_created:, contacts_created:, contact_skipped: }
  end

  # Fetches emails for each selected domain and creates Communication records.
  # analyze: true → runs AiAnalysisService on each email
  # Returns { emails_imported:, emails_skipped: }
  def self.import_emails(selected_domains:, access_token:, analyze: false)
    emails_imported = 0
    emails_skipped  = 0

    selected_domains.each do |domain_data|
      domain  = domain_data["domain"]
      company = Company.find_by(website: domain)
      next unless company

      message_ids = fetch_emails_for_domain(access_token, domain)

      message_ids.each do |msg_id|
        next if Communication.exists?(external_id: msg_id)

        message = fetch_full_message(access_token, msg_id)
        next unless message

        headers     = extract_headers(message)
        subject     = headers["Subject"] || "(件名なし)"
        from_email  = parse_email_header(headers["From"] || "").first&.dig(:email)
        date        = parse_date(headers["Date"])
        body        = extract_body(message["payload"] || {})
        content     = "件名: #{subject}\n差出人: #{headers['From']}\n\n#{body}".strip

        contact = Contact.find_by(email: from_email) if from_email

        comm_attrs = {
          channel:     "email",
          content:     content,
          recorded_at: date,
          company:     company,
          contact:     contact,
          external_id: msg_id
        }

        if analyze && content.length > 10
          analysis = AiAnalysisService.new.analyze_communication(content: content, channel: "email")
          comm_attrs.merge!(
            summary:      analysis["summary"],
            sentiment:    analysis["sentiment"],
            keywords:     analysis["keywords"],
            action_items: analysis["action_items"],
            analyzed_at:  Time.current
          )
        end

        Communication.create!(comm_attrs)
        emails_imported += 1
      rescue StandardError
        emails_skipped += 1
        next
      end
    end

    { emails_imported:, emails_skipped: }
  end

  # Demo import: creates Communications from demo email data (no OAuth required)
  def self.import_demo_emails(selected_domains:, analyze: false)
    emails_imported = 0

    selected_domains.each do |domain_data|
      domain  = domain_data["domain"]
      company = Company.find_by(website: domain)
      next unless company

      demo_emails_for(domain).each do |email_data|
        next if Communication.exists?(external_id: email_data[:id])

        contact = Contact.find_by(email: email_data[:from_email])
        content = "件名: #{email_data[:subject]}\n差出人: #{email_data[:from]}\n\n#{email_data[:body]}"

        comm_attrs = {
          channel:     "email",
          content:     content,
          recorded_at: email_data[:date],
          company:     company,
          contact:     contact,
          external_id: email_data[:id]
        }

        if analyze && content.length > 10
          analysis = AiAnalysisService.new.analyze_communication(content: content, channel: "email")
          comm_attrs.merge!(
            summary:      analysis["summary"],
            sentiment:    analysis["sentiment"],
            keywords:     analysis["keywords"],
            action_items: analysis["action_items"],
            analyzed_at:  Time.current
          )
        end

        Communication.create!(comm_attrs)
        emails_imported += 1
      rescue StandardError
        next
      end
    end

    { emails_imported:, emails_skipped: 0 }
  end

  # ── Private ─────────────────────────────────────────────────────────────────
  private_class_method def self.fetch_message_list(access_token, max_messages)
    response = HTTParty.get(
      "#{GMAIL_API_BASE}/messages",
      query:   { maxResults: max_messages, q: "in:sent OR in:inbox" },
      headers: auth_headers(access_token)
    )
    raise GmailError, "Gmail API error: #{response.code}" unless response.success?

    (response.parsed_response["messages"] || []).map { |m| m["id"] }
  rescue StandardError => e
    raise GmailError, e.message
  end

  private_class_method def self.extract_emails_from_messages(access_token, message_ids)
    emails = []
    message_ids.first(50).each do |id|
      response = HTTParty.get(
        "#{GMAIL_API_BASE}/messages/#{id}",
        query:   { format: "metadata", metadataHeaders: %w[From To] },
        headers: auth_headers(access_token)
      )
      next unless response.success?

      (response.dig("payload", "headers") || []).each do |h|
        next unless %w[From To].include?(h["name"])
        emails.concat(parse_email_header(h["value"]))
      end
    rescue StandardError
      next
    end
    emails.uniq { |e| e[:email] }
  end

  private_class_method def self.count_emails_for_domain(access_token, domain)
    response = HTTParty.get(
      "#{GMAIL_API_BASE}/messages",
      query:   { maxResults: 1, q: "from:@#{domain} OR to:@#{domain}" },
      headers: auth_headers(access_token)
    )
    return 0 unless response.success?
    response.parsed_response["resultSizeEstimate"].to_i
  rescue StandardError
    0
  end

  private_class_method def self.fetch_emails_for_domain(access_token, domain)
    response = HTTParty.get(
      "#{GMAIL_API_BASE}/messages",
      query:   { maxResults: MAX_EMAILS_PER_DOMAIN, q: "from:@#{domain} OR to:@#{domain}" },
      headers: auth_headers(access_token)
    )
    return [] unless response.success?
    (response.parsed_response["messages"] || []).map { |m| m["id"] }
  rescue StandardError
    []
  end

  private_class_method def self.fetch_full_message(access_token, message_id)
    response = HTTParty.get(
      "#{GMAIL_API_BASE}/messages/#{message_id}",
      query:   { format: "full" },
      headers: auth_headers(access_token)
    )
    return nil unless response.success?
    response.parsed_response
  rescue StandardError
    nil
  end

  private_class_method def self.extract_headers(message)
    (message.dig("payload", "headers") || [])
      .each_with_object({}) { |h, acc| acc[h["name"]] = h["value"] }
  end

  private_class_method def self.extract_body(payload)
    mime = payload["mimeType"].to_s

    # Simple non-multipart message
    if mime.start_with?("text/plain")
      data = payload.dig("body", "data").to_s
      return safe_decode64(data)
    end

    # Multipart: search recursively for text/plain first, then text/html
    parts = collect_parts(payload)
    plain = parts.find { |p| p["mimeType"] == "text/plain" }
    return safe_decode64(plain.dig("body", "data").to_s) if plain

    html = parts.find { |p| p["mimeType"] == "text/html" }
    return strip_html(safe_decode64(html.dig("body", "data").to_s)) if html

    ""
  end

  private_class_method def self.collect_parts(payload, acc = [])
    (payload["parts"] || []).each do |part|
      acc << part
      collect_parts(part, acc)
    end
    acc
  end

  private_class_method def self.safe_decode64(data)
    return "" if data.blank?
    Base64.urlsafe_decode64(data).force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace)
  rescue ArgumentError
    ""
  end

  private_class_method def self.strip_html(html)
    html.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
  end

  private_class_method def self.parse_date(date_str)
    Time.parse(date_str)
  rescue StandardError
    Time.current
  end

  private_class_method def self.group_by_domain(emails)
    grouped = {}
    emails.each do |entry|
      domain = entry[:email].split("@").last.to_s.downcase
      next if domain.blank? || EXCLUDED_DOMAINS.include?(domain)

      grouped[domain] ||= { domain:, company_name: domain_to_company_name(domain), contacts: [], email_count: 0 }
      grouped[domain][:contacts] << { name: entry[:name], email: entry[:email] }
    end

    grouped.values
           .reject { |g| g[:contacts].empty? }
           .sort_by { |g| -g[:contacts].size }
  end

  private_class_method def self.parse_email_header(value)
    return [] if value.blank?

    results = []
    value.split(/,\s*(?=(?:[^"]*"[^"]*")*[^"]*$)/).each do |addr|
      addr = addr.strip
      if (m = addr.match(/(.*?)\s*<([^>]+)>/))
        name  = m[1].strip.gsub(/\A"|"\z/, "")
        email = m[2].strip.downcase
      else
        name  = nil
        email = addr.downcase
      end
      next unless email.include?("@")
      results << { name: name.presence, email: email }
    end
    results
  end

  private_class_method def self.domain_to_company_name(domain)
    domain.split(".").first.to_s.split(/[-_]/).map(&:capitalize).join(" ")
  end

  private_class_method def self.email_to_name(email)
    email.split("@").first.to_s.split(/[._-]/).map(&:capitalize).join(" ")
  end

  private_class_method def self.auth_headers(access_token)
    { "Authorization" => "Bearer #{access_token}" }
  end

  # ── Demo data ────────────────────────────────────────────────────────────────
  private_class_method def self.demo_preview_data
    [
      {
        domain: "techcorp.co.jp", company_name: "Techcorp", email_count: 8,
        contacts: [
          { name: "田中 太郎", email: "tanaka@techcorp.co.jp" },
          { name: "佐藤 花子", email: "sato@techcorp.co.jp" }
        ]
      },
      {
        domain: "globalventures.com", company_name: "Global Ventures", email_count: 15,
        contacts: [
          { name: "John Smith",  email: "john.smith@globalventures.com" },
          { name: "Emily Chen",  email: "e.chen@globalventures.com" },
          { name: "Mark Wilson", email: "m.wilson@globalventures.com" }
        ]
      },
      {
        domain: "innovate-labs.jp", company_name: "Innovate Labs", email_count: 4,
        contacts: [
          { name: "山田 一郎", email: "yamada@innovate-labs.jp" }
        ]
      },
      {
        domain: "nextstep-inc.com", company_name: "Nextstep Inc", email_count: 11,
        contacts: [
          { name: "Sarah Johnson", email: "sarah@nextstep-inc.com" },
          { name: "Tom Brown",     email: "tom.b@nextstep-inc.com" }
        ]
      },
      {
        domain: "futuretech.io", company_name: "Futuretech", email_count: 6,
        contacts: [
          { name: "Alex Lee", email: "alex@futuretech.io" },
          { name: "Mia Park", email: "mia@futuretech.io" }
        ]
      }
    ]
  end

  private_class_method def self.demo_emails_for(domain)
    base = {
      "techcorp.co.jp" => [
        {
          id: "demo-techcorp-1",
          subject: "製品デモのご依頼について",
          from: "田中 太郎 <tanaka@techcorp.co.jp>",
          from_email: "tanaka@techcorp.co.jp",
          date: 3.days.ago,
          body: "お世話になっております。弊社では現在、営業支援ツールの導入を検討しており、貴社のDeal Forwardについてデモを拝見できればと思いご連絡しました。来週以降でご都合のよい日時をご教示いただけますでしょうか。"
        },
        {
          id: "demo-techcorp-2",
          subject: "Re: 製品デモのご依頼について",
          from: "佐藤 花子 <sato@techcorp.co.jp>",
          from_email: "sato@techcorp.co.jp",
          date: 2.days.ago,
          body: "田中よりご連絡の件、私も同席させていただきたいと思っております。特に、AIが自動生成するプレイブック機能と、CRM連携の部分に興味があります。導入コストについても詳しく教えていただけますか？"
        }
      ],
      "globalventures.com" => [
        {
          id: "demo-global-1",
          subject: "Partnership Inquiry - AI Sales Platform",
          from: "John Smith <john.smith@globalventures.com>",
          from_email: "john.smith@globalventures.com",
          date: 5.days.ago,
          body: "Hi, I came across your AI-powered sales platform and I'm very interested in how it handles multi-channel communication analysis. We currently have a team of 50 sales reps and are looking to scale our outreach. Could you share pricing details and case studies?"
        },
        {
          id: "demo-global-2",
          subject: "Re: Partnership Inquiry",
          from: "Emily Chen <e.chen@globalventures.com>",
          from_email: "e.chen@globalventures.com",
          date: 4.days.ago,
          body: "Following up on John's inquiry. We specifically want to understand how the Slack and Teams integration works for capturing sales conversations. Our sales ops team has been evaluating 3 platforms and yours is our top choice so far."
        }
      ],
      "innovate-labs.jp" => [
        {
          id: "demo-innovate-1",
          subject: "導入検討のご相談",
          from: "山田 一郎 <yamada@innovate-labs.jp>",
          from_email: "yamada@innovate-labs.jp",
          date: 7.days.ago,
          body: "はじめまして。弊社はスタートアップで、営業チームが3名から10名に拡大する予定です。AIエージェントが営業活動を自律実行するという機能が非常に魅力的です。まずはトライアルから始められますか？"
        }
      ],
      "nextstep-inc.com" => [
        {
          id: "demo-nextstep-1",
          subject: "Renewal Discussion",
          from: "Sarah Johnson <sarah@nextstep-inc.com>",
          from_email: "sarah@nextstep-inc.com",
          date: 1.day.ago,
          body: "Our current contract is up for renewal next month. We've been very happy with the chatbot lead capture feature. However, we'd like to discuss upgrading to include the full AI agent capabilities. Can we schedule a call this week?"
        }
      ],
      "futuretech.io" => [
        {
          id: "demo-futuretech-1",
          subject: "API Integration Questions",
          from: "Alex Lee <alex@futuretech.io>",
          from_email: "alex@futuretech.io",
          date: 6.days.ago,
          body: "We're building a custom integration between your platform and our internal CRM. I have some questions about the agent API endpoints, specifically around the webhook notifications and the playbook execution flow."
        }
      ]
    }
    base[domain] || []
  end
end
