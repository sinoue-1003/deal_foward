# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_18_000001) do
  create_schema "extensions"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_net"
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "public.agent_reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action_taken"
    t.uuid "company_id"
    t.uuid "contact_id"
    t.datetime "created_at", null: false
    t.jsonb "insights", default: {}
    t.jsonb "next_recommended_actions", default: []
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_agent_reports_on_company_id"
    t.index ["contact_id"], name: "index_agent_reports_on_contact_id"
  end

  create_table "public.agent_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.jsonb "messages", default: [], null: false
    t.jsonb "pending_approval"
    t.uuid "playbook_id"
    t.string "status", default: "analyzing", null: false
    t.jsonb "tool_calls", default: [], null: false
    t.string "trigger", default: "manual", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "status"], name: "index_agent_runs_on_company_id_and_status"
    t.index ["company_id"], name: "index_agent_runs_on_company_id"
    t.index ["playbook_id"], name: "index_agent_runs_on_playbook_id"
    t.index ["status"], name: "index_agent_runs_on_status"
  end

  create_table "public.chat_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "contact_id"
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "intent_score", default: 0
    t.jsonb "messages", default: []
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_chat_sessions_on_company_id"
    t.index ["contact_id"], name: "index_chat_sessions_on_contact_id"
  end

  create_table "public.communications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "action_items", default: []
    t.datetime "analyzed_at"
    t.string "channel", null: false
    t.uuid "company_id"
    t.uuid "contact_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.string "external_id"
    t.jsonb "keywords", default: []
    t.datetime "recorded_at"
    t.string "sentiment"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_communications_on_channel"
    t.index ["company_id"], name: "index_communications_on_company_id"
    t.index ["contact_id"], name: "index_communications_on_contact_id"
    t.index ["external_id"], name: "index_communications_on_external_id", unique: true
  end

  create_table "public.companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address"
    t.bigint "annual_revenue"
    t.bigint "capital"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "crm_id"
    t.text "description"
    t.integer "employee_count"
    t.string "industry"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "website"
  end

  create_table "public.contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.string "crm_id"
    t.string "department"
    t.text "description"
    t.string "email"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "mobile"
    t.string "phone"
    t.string "position"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_contacts_on_company_id"
  end

  create_table "public.deal_contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "contact_id", null: false
    t.datetime "created_at", null: false
    t.uuid "deal_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_deal_contacts_on_contact_id"
    t.index ["deal_id", "contact_id"], name: "index_deal_contacts_on_deal_id_and_contact_id", unique: true
    t.index ["deal_id"], name: "index_deal_contacts_on_deal_id"
  end

  create_table "public.deals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2
    t.date "close_date"
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.string "lost_reason"
    t.text "notes"
    t.string "owner"
    t.integer "probability", default: 0
    t.string "stage", default: "prospect"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_deals_on_company_id"
    t.index ["stage"], name: "index_deals_on_stage"
  end

  create_table "public.integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.string "error_message"
    t.string "integration_type", null: false
    t.datetime "last_synced_at"
    t.string "status", default: "disconnected"
    t.datetime "updated_at", null: false
    t.index ["integration_type"], name: "index_integrations_on_integration_type", unique: true
  end

  create_table "public.playbook_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "action_content"
    t.datetime "created_at", null: false
    t.datetime "executed_at"
    t.string "executed_by"
    t.uuid "playbook_id", null: false
    t.uuid "playbook_step_id", null: false
    t.text "result"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["playbook_id"], name: "index_playbook_executions_on_playbook_id"
    t.index ["playbook_step_id"], name: "index_playbook_executions_on_playbook_step_id"
  end

  create_table "public.playbook_steps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action_type", null: false
    t.string "channel"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "due_in_hours"
    t.string "executed_by"
    t.string "executor_type", null: false
    t.uuid "playbook_id", null: false
    t.string "status", default: "pending"
    t.integer "step_index", null: false
    t.string "target"
    t.text "template"
    t.datetime "updated_at", null: false
    t.index ["playbook_id", "step_index"], name: "index_playbook_steps_on_playbook_id_and_step_index", unique: true
    t.index ["playbook_id"], name: "index_playbook_steps_on_playbook_id"
    t.index ["status"], name: "index_playbook_steps_on_status"
  end

  create_table "public.playbooks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.uuid "contact_id"
    t.datetime "created_at", null: false
    t.string "created_by", default: "ai_agent"
    t.text "objective"
    t.text "situation_summary"
    t.string "status", default: "active"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_playbooks_on_company_id"
    t.index ["contact_id"], name: "index_playbooks_on_contact_id"
    t.index ["status"], name: "index_playbooks_on_status"
  end

  add_foreign_key "public.agent_reports", "public.companies"
  add_foreign_key "public.agent_reports", "public.contacts"
  add_foreign_key "public.agent_runs", "public.companies"
  add_foreign_key "public.agent_runs", "public.playbooks"
  add_foreign_key "public.chat_sessions", "public.companies"
  add_foreign_key "public.chat_sessions", "public.contacts"
  add_foreign_key "public.communications", "public.companies"
  add_foreign_key "public.communications", "public.contacts"
  add_foreign_key "public.contacts", "public.companies"
  add_foreign_key "public.deal_contacts", "public.contacts"
  add_foreign_key "public.deal_contacts", "public.deals"
  add_foreign_key "public.deals", "public.companies"
  add_foreign_key "public.playbook_executions", "public.playbook_steps"
  add_foreign_key "public.playbook_executions", "public.playbooks"
  add_foreign_key "public.playbook_steps", "public.playbooks"
  add_foreign_key "public.playbooks", "public.companies"
  add_foreign_key "public.playbooks", "public.contacts"

end
