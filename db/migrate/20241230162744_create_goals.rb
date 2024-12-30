class CreateGoals < ActiveRecord::Migration[7.2]
  def change
    create_table :goals, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :type, null: false
      t.decimal :target_amount, null: false, precision: 19, scale: 4
      t.decimal :starting_amount, null: false, precision: 19, scale: 4
      t.date :start_date, null: false
      t.date :target_date, null: false
      t.timestamps
    end
  end
end
