Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "health", to: "health#show"

    # AI Agent endpoints (for AI agents to consume)
    namespace :agent do
      post   "report",          to: "actions#report"
      post   "request_context", to: "actions#request_context"
      post   "trigger_playbook",to: "actions#trigger_playbook"
      get    "communications",  to: "actions#communications"
      get    "contacts/:company_id", to: "actions#contacts"
      get    "playbook/:id",    to: "actions#playbook"
      patch  "playbook/:id/step/:step_index", to: "actions#update_step"

      # Agent run management
      post   "run",               to: "runs#create"
      get    "runs",              to: "runs#index"
      get    "runs/:id",          to: "runs#show"
      post   "runs/:id/approve",  to: "runs#approve"
      post   "runs/:id/reject",   to: "runs#reject"
    end

    # OAuth 2.0 flows
    get "oauth/:integration_type/authorize", to: "oauth#authorize"
    get "oauth/callback",                    to: "oauth#callback"

    # Chatbot endpoints
    resources :chatbot_sessions, path: "chatbot/sessions", only: [:index, :show, :create] do
      member do
        post :message
      end
    end
    post "chatbot/session", to: "chatbot_sessions#create"

    # Playbooks
    resources :playbooks do
      member do
        post :execute
        get  :status   # AI + human shared status view
      end
    end

    # Communications (Slack, Teams, Zoom, Meet, CRM data)
    resources :communications, only: [:index, :show, :create] do
      collection do
        post :analyze
      end
    end

    # Integrations management
    resources :integrations, only: [:index] do
      member do
        post   :connect
        delete :disconnect
        post   :sync
      end
    end

    # Deals / pipeline
    resources :deals

    # Dashboard
    namespace :dashboard do
      get "overview",       to: "overviews#show"
      get "agent_activity", to: "agent_activities#show"
      get "pipeline",       to: "pipelines#show"
    end
  end
end
