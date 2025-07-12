class AddValuationKind < ActiveRecord::Migration[7.2]
  def change
    add_column :valuations, :kind, :string, default: "reconciliation", null: false
  end
end
