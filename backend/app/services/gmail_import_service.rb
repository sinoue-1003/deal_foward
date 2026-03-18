class GmailImportService
  GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1/users/me"
  # Personal/system domains to exclude from company grouping
  EXCLUDED_DOMAINS = %w[
    gmail.com yahoo.co.jp yahoo.com outlook.com hotmail.com
    icloud.com me.com mac.com live.com msn.com
    googlemail.com protonmail.com
  ].freeze

  class GmailError < StandardError; end

  # Returns domain-grouped preview data without saving anything.
  # If access_token is nil/invalid, returns demo data for UI development.
  def self.preview(access_token:, max_messages: 100)
    if access_token.blank?
      return demo_preview_data
    end

    messages = fetch_message_list(access_token, max_messages)
    return demo_preview_data if messages.empty?

    emails = extract_emails_from_messages(access_token, messages)
    group_by_domain(emails)
  rescue GmailError
    demo_preview_data
  end

  # Creates Company and Contact records from selected domain data.
  # selected_domains: [{ domain:, company_name:, contacts: [{name:, email:}] }]
  # Returns { companies_created:, contacts_created:, skipped: }
  def self.import(selected_domains:)
    companies_created = 0
    contacts_created  = 0
    skipped           = 0

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
          skipped += 1
        end
      end
    end

    { companies_created:, contacts_created:, skipped: }
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
    # Limit individual fetches to avoid long load times in preview
    message_ids.first(50).each do |id|
      response = HTTParty.get(
        "#{GMAIL_API_BASE}/messages/#{id}",
        query:   { format: "metadata", metadataHeaders: %w[From To] },
        headers: auth_headers(access_token)
      )
      next unless response.success?

      headers = (response.dig("payload", "headers") || [])
      headers.each do |h|
        next unless %w[From To].include?(h["name"])
        parsed = parse_email_header(h["value"])
        emails.concat(parsed)
      end
    rescue StandardError
      next
    end
    emails.uniq { |e| e[:email] }
  end

  private_class_method def self.group_by_domain(emails)
    grouped = {}
    emails.each do |entry|
      domain = entry[:email].split("@").last.to_s.downcase
      next if domain.blank? || EXCLUDED_DOMAINS.include?(domain)

      grouped[domain] ||= { domain:, company_name: domain_to_company_name(domain), contacts: [] }
      grouped[domain][:contacts] << { name: entry[:name], email: entry[:email] }
    end

    grouped.values
           .reject { |g| g[:contacts].empty? }
           .sort_by { |g| -g[:contacts].size }
  end

  # Parse RFC 2822-style "Display Name <email@domain.com>" or bare email
  private_class_method def self.parse_email_header(value)
    return [] if value.blank?

    results = []
    # Handle comma-separated addresses
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
    # "acme-corp.co.jp" → "Acme Corp"
    domain.split(".").first.to_s
          .split(/[-_]/).map(&:capitalize).join(" ")
  end

  private_class_method def self.email_to_name(email)
    local = email.split("@").first.to_s
    local.split(/[._-]/).map(&:capitalize).join(" ")
  end

  private_class_method def self.auth_headers(access_token)
    { "Authorization" => "Bearer #{access_token}" }
  end

  # ── Demo data (used when no OAuth token is available) ──────────────────────
  private_class_method def self.demo_preview_data
    [
      {
        domain: "techcorp.co.jp",
        company_name: "Techcorp",
        contacts: [
          { name: "田中 太郎", email: "tanaka@techcorp.co.jp" },
          { name: "佐藤 花子", email: "sato@techcorp.co.jp" }
        ]
      },
      {
        domain: "globalventures.com",
        company_name: "Global Ventures",
        contacts: [
          { name: "John Smith",  email: "john.smith@globalventures.com" },
          { name: "Emily Chen",  email: "e.chen@globalventures.com" },
          { name: "Mark Wilson", email: "m.wilson@globalventures.com" }
        ]
      },
      {
        domain: "innovate-labs.jp",
        company_name: "Innovate Labs",
        contacts: [
          { name: "山田 一郎", email: "yamada@innovate-labs.jp" }
        ]
      },
      {
        domain: "nextstep-inc.com",
        company_name: "Nextstep Inc",
        contacts: [
          { name: "Sarah Johnson", email: "sarah@nextstep-inc.com" },
          { name: "Tom Brown",     email: "tom.b@nextstep-inc.com" }
        ]
      },
      {
        domain: "futuretech.io",
        company_name: "Futuretech",
        contacts: [
          { name: "Alex Lee",  email: "alex@futuretech.io" },
          { name: "Mia Park",  email: "mia@futuretech.io" }
        ]
      }
    ]
  end
end
