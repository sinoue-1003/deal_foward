class SequenceStep < ApplicationRecord
  belongs_to :tenant
  belongs_to :sequence

  ACTION_TYPES = %w[email call linkedin_message sms task wait].freeze

  validates :step_index,  presence: true
  validates :action_type, inclusion: { in: ACTION_TYPES }
  validates :day_offset,  numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(:step_index) }
end
