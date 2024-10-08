class AddDebtAccountViews < ActiveRecord::Migration[7.2]
  def change
    change_table :loans do |t|
      t.string :rate_type
      t.decimal :interest_rate, precision: 10, scale: 2
      t.integer :term_months
    end

    change_table :credit_cards do |t|
      t.decimal :available_credit, precision: 10, scale: 2
      t.decimal :minimum_payment, precision: 10, scale: 2
      t.decimal :apr, precision: 10, scale: 2
      t.date :expiration_date
      t.decimal :annual_fee, precision: 10, scale: 2
    end
  end
end
