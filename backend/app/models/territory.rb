class Territory < ApplicationRecord
  belongs_to :tenant
  belongs_to :parent_territory, class_name: "Territory", optional: true
  belongs_to :owner, class_name: "User", optional: true

  has_many :sub_territories, class_name: "Territory", foreign_key: :parent_territory_id, dependent: :nullify
  has_many :territory_assignments, dependent: :destroy
  has_many :companies, through: :territory_assignments

  TERRITORY_TYPES = %w[geographic vertical account_size product].freeze

  validates :name,           presence: true
  validates :territory_type, inclusion: { in: TERRITORY_TYPES }
end
