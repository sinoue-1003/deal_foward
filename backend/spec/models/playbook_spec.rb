require "rails_helper"

RSpec.describe Playbook, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:status).in_array(Playbook::STATUSES) }
  end

  describe "associations" do
    it { should belong_to(:company).optional }
    it { should belong_to(:contact).optional }
    it { should have_many(:playbook_steps).dependent(:destroy) }
    it { should have_many(:playbook_executions).dependent(:destroy) }
  end

  describe "#next_action" do
    let(:playbook) { create(:playbook) }

    context "when there are pending steps" do
      let!(:step1) { create(:playbook_step, playbook: playbook, step_index: 0, status: "completed") }
      let!(:step2) { create(:playbook_step, playbook: playbook, step_index: 1, status: "pending") }

      it "returns the first pending step" do
        expect(playbook.next_action).to eq(step2)
      end
    end

    context "when there are no pending steps" do
      let!(:step) { create(:playbook_step, playbook: playbook, step_index: 0, status: "completed") }

      it "returns nil" do
        expect(playbook.next_action).to be_nil
      end
    end
  end

  describe "#status_summary" do
    let(:playbook) { create(:playbook, situation_summary: "Test situation") }

    context "with no steps" do
      it "returns a hash with the expected keys" do
        summary = playbook.status_summary
        expect(summary).to include(:situation, :progress, :next_action, :status)
      end

      it "shows 0 progress" do
        expect(playbook.status_summary[:progress]).to eq("0/0ステップ完了")
      end

      it "has nil next_action" do
        expect(playbook.status_summary[:next_action]).to be_nil
      end
    end

    context "with pending and completed steps" do
      let!(:step1) { create(:playbook_step, playbook: playbook, step_index: 0, status: "completed") }
      let!(:step2) { create(:playbook_step, playbook: playbook, step_index: 1, status: "pending", action_type: "send_email", executor_type: "ai") }

      it "shows correct progress" do
        expect(playbook.status_summary[:progress]).to eq("1/2ステップ完了")
      end

      it "includes next_action info" do
        next_action = playbook.status_summary[:next_action]
        expect(next_action).to include(
          step: 1,
          action_type: "send_email",
          executor_type: "ai"
        )
      end
    end
  end

  describe "#maybe_auto_complete!" do
    let(:playbook) { create(:playbook, status: "active") }

    context "when all steps are in terminal states" do
      let!(:step1) { create(:playbook_step, playbook: playbook, step_index: 0, status: "completed") }
      let!(:step2) { create(:playbook_step, playbook: playbook, step_index: 1, status: "skipped") }

      it "sets status to completed" do
        playbook.maybe_auto_complete!
        expect(playbook.reload.status).to eq("completed")
      end
    end

    context "when some steps are still pending" do
      let!(:step1) { create(:playbook_step, playbook: playbook, step_index: 0, status: "completed") }
      let!(:step2) { create(:playbook_step, playbook: playbook, step_index: 1, status: "pending") }

      it "does not change status" do
        playbook.maybe_auto_complete!
        expect(playbook.reload.status).to eq("active")
      end
    end

    context "when there are no steps" do
      it "does not change status" do
        playbook.maybe_auto_complete!
        expect(playbook.reload.status).to eq("active")
      end
    end
  end
end
