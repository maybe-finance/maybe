class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :family_id, null: false, foreign_key: true, type: :uuid

      t.string :status, null: false

      t.string :stripe_id
      t.string :name
      t.decimal :amount, precision: 19, scale: 4
      t.string :currency
      t.string :interval
      t.datetime :current_period_end

      t.timestamps
    end


    reversible do |dir|
      dir.up do
      end
    end
  end
end
