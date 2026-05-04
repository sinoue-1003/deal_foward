class TerritoryAssignment < ApplicationRecord
  belongs_to :tenant
  belongs_to :territory
  belongs_to :company
  belongs_to :user, optional: true
end
