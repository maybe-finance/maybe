class AddStartDateToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :start_date, :date # A user-defined, explicit start date for an account we don't have the full history for
  end
end
