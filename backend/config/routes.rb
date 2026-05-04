Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "health", to: "health#show"

    # ── AI Agent エンドポイント ──────────────────────────────────────
    namespace :agent do
      post  "report",           to: "actions#report"
      post  "request_context",  to: "actions#request_context"
      post  "trigger_playbook", to: "actions#trigger_playbook"
      get   "communications",   to: "actions#communications"
      get   "contacts/:company_id", to: "actions#contacts"
      get   "playbook/:id",         to: "actions#playbook"
      patch "playbook/:id/step/:step_index", to: "actions#update_step"

      post  "run",              to: "runs#create"
      get   "runs",             to: "runs#index"
      get   "runs/:id",         to: "runs#show"
      post  "runs/:id/approve", to: "runs#approve"
      post  "runs/:id/reject",  to: "runs#reject"
    end

    # ── OAuth 2.0 ───────────────────────────────────────────────────
    get "oauth/:integration_type/authorize", to: "oauth#authorize"
    get "oauth/callback",                    to: "oauth#callback"

    # ── CRM コア ────────────────────────────────────────────────────
    resources :leads do
      member { post :convert }
    end

    resources :deals do
      member do
        get  :stage_history  # ステージ変遷履歴
      end
    end

    resources :contacts, only: [ :index, :show, :create, :update, :destroy ]
    resources :companies, only: [ :index, :show, :create, :update, :destroy ]

    # ── CPQ（見積・製品・契約）────────────────────────────────────
    resources :products
    resources :quotes
    resources :contracts do
      member { post :renew }
    end

    # ── セールスエンゲージメント ────────────────────────────────────
    resources :sequences do
      member { post :enroll }
    end
    resources :tasks

    # ── コンバセーション インテリジェンス ───────────────────────────
    resources :meetings do
      member { get :insight }
    end

    # ── コミュニケーション ──────────────────────────────────────────
    resources :communications, only: [ :index, :show, :create ] do
      collection { post :analyze }
    end

    # ── チャットbot ─────────────────────────────────────────────────
    resources :chatbot_sessions, path: "chatbot/sessions", only: [ :index, :show, :create ] do
      member { post :message }
    end
    post "chatbot/session", to: "chatbot_sessions#create"

    # ── プレイブック ────────────────────────────────────────────────
    resources :playbooks do
      member do
        post :execute
        get  :status
      end
    end

    # ── 統合管理 ────────────────────────────────────────────────────
    resources :integrations, only: [ :index ] do
      member do
        post   :connect
        delete :disconnect
        post   :sync
      end
    end

    # ── Gmail インポート ────────────────────────────────────────────
    get  "gmail/preview", to: "gmail_import#preview"
    post "gmail/import",  to: "gmail_import#import"

    # ── ダッシュボード ──────────────────────────────────────────────
    namespace :dashboard do
      get "overview",       to: "overviews#show"
      get "agent_activity", to: "agent_activities#show"
      get "pipeline",       to: "pipelines#show"
    end
  end
end
