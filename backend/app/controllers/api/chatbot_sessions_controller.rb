module Api
  class ChatbotSessionsController < BaseController
    # GET /api/chatbot/sessions
    def index
      sessions = ChatSession.includes(:company, :contact)
        .order(created_at: :desc)
        .limit(params.fetch(:limit, 50).to_i)

      render json: sessions.map { |s|
        s.as_json.merge(
          company_name: s.company&.name,
          contact_name: s.contact&.name,
          intent_level: s.intent_level,
          message_count: s.messages.size
        )
      }
    end

    # GET /api/chatbot/sessions/:id
    def show
      session = ChatSession.find(params[:id])
      render json: session.as_json.merge(
        company: session.company,
        contact: session.contact,
        intent_level: session.intent_level
      )
    end

    # POST /api/chatbot/session
    def create
      session = ChatSession.create!(
        messages: [],
        intent_score: 0,
        status: "active"
      )
      render json: session, status: :created
    end

    # POST /api/chatbot/sessions/:id/message
    def message
      session = ChatSession.find(params[:id])
      user_message = params.require(:message)

      result = ChatbotService.new.respond(session: session, user_message: user_message)
      render json: result
    end
  end
end
