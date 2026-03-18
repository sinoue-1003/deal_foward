class DealContact < ApplicationRecord
  belongs_to :deal
  belongs_to :contact

  ROLES = %w[decision_maker influencer user champion other].freeze
  validates :role, inclusion: { in: ROLES }, allow_nil: true
end
