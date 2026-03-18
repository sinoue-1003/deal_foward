require "rails_helper"

RSpec.describe Deal, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:stage).in_array(Deal::STAGES) }
  end

  describe "associations" do
    it { should belong_to(:company).optional }
    it { should have_many(:deal_contacts).dependent(:destroy) }
    it { should have_many(:contacts).through(:deal_contacts) }
  end

  describe "stage values" do
    Deal::STAGES.each do |stage|
      it "accepts '#{stage}' as a valid stage" do
        deal = build(:deal, stage: stage)
        expect(deal).to be_valid
      end
    end

    it "rejects invalid stages" do
      deal = build(:deal, stage: "invalid_stage")
      expect(deal).not_to be_valid
    end
  end
end
