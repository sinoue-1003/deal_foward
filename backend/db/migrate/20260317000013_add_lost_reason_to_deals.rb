class AddLostReasonToDeals < ActiveRecord::Migration[8.1]
  def change
    add_column :deals, :lost_reason, :string
    # lost_reason examples: price, competitor, timing, no_budget, no_decision, other
  end
end
