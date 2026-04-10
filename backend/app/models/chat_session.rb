class ChatSession < ApplicationRecord
  belongs_to :tenant
  belongs_to :company,     optional: true
  belongs_to :contact,     optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  STATUSES = %w[active ended converted].freeze
  SOURCES  = %w[organic paid social referral direct email other].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }, allow_nil: true
  validates :intent_score, numericality: { in: 0..100 }, allow_nil: true

  def intent_level
    case intent_score
    when 80..100 then "hot"
    when 60..79  then "warm"
    when 40..59  then "cool"
    else              "cold"
    end
  end
end
