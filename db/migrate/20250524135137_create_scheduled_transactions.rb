class CreateScheduledTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :scheduled_transactions, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :category, null: true, foreign_key: true, type: :uuid
      t.references :merchant, null: true, foreign_key: true, type: :uuid
      t.string :description
      t.decimal :amount
      t.string :currency
      t.string :frequency
      t.integer :installments
      t.integer :current_installment, default: 0
      t.date :next_occurrence_date
      t.date :end_date

      t.timestamps
    end

    add_index :scheduled_transactions, :next_occurrence_date
  end
end
