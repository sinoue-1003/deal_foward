require "rails_helper"

RSpec.describe PlaybookStep, type: :model do
  describe "validations" do
    it { should validate_presence_of(:step_index) }
    it { should validate_inclusion_of(:action_type).in_array(PlaybookStep::ACTION_TYPES) }
    it { should validate_inclusion_of(:executor_type).in_array(PlaybookStep::EXECUTOR_TYPES) }
    it { should validate_inclusion_of(:status).in_array(PlaybookStep::STATUSES) }
  end

  describe "associations" do
    it { should belong_to(:playbook) }
    it { should have_many(:playbook_executions).dependent(:destroy) }
  end

  describe "#pending?" do
    it "returns true when status is pending" do
      step = build(:playbook_step, status: "pending")
      expect(step.pending?).to be true
    end

    it "returns false when status is completed" do
      step = build(:playbook_step, status: "completed")
      expect(step.pending?).to be false
    end
  end

  describe "#terminal?" do
    %w[completed skipped failed].each do |status|
      it "returns true for status '#{status}'" do
        step = build(:playbook_step, status: status)
        expect(step.terminal?).to be true
      end
    end

    %w[pending in_progress].each do |status|
      it "returns false for status '#{status}'" do
        step = build(:playbook_step, status: status)
        expect(step.terminal?).to be false
      end
    end
  end
end
