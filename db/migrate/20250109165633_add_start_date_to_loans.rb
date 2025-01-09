class AddStartDateToLoans < ActiveRecord::Migration[7.2]
  def change
    add_column :loans, :start_date, :date
  end
end
