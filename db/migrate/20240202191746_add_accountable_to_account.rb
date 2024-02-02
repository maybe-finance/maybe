class AddAccountableToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :accountable_type, :string
    add_column :accounts, :accountable_id, :uuid
  end
end
