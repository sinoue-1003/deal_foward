FactoryBot.define do
  factory :agent_run do
    association :company
    status { "analyzing" }
    trigger { "manual" }
    messages { [] }
    tool_calls { [] }
    pending_approval { nil }
  end
end
