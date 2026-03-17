class ChatSession < ApplicationRecord
  belongs_to :company, optional: true
  belongs_to :contact, optional: true

  validates :status, inclusion: { in: %w[active ended converted] }

  def intent_level
    case intent_score
    when 80..100 then "hot"
    when 60..79  then "warm"
    when 40..59  then "cool"
    else              "cold"
    end
  end
end
