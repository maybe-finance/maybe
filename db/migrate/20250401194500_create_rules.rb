class CreateRules < ActiveRecord::Migration[7.2]
  def change
    create_table :rules, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid

      t.string :resource_type, null: false
      t.date :effective_date
      t.boolean :active, null: false, default: false
      t.timestamps
    end

    create_table :rule_conditions, id: :uuid do |t|
      t.references :rule, foreign_key: true, type: :uuid
      t.references :parent, foreign_key: { to_table: :rule_conditions }, type: :uuid

      t.string :condition_type, null: false
      t.string :operator, null: false
      t.string :value
      t.timestamps
    end

    create_table :rule_actions, id: :uuid do |t|
      t.references :rule, null: false, foreign_key: true, type: :uuid

      t.string :action_type, null: false
      t.string :value
      t.timestamps
    end
  end
end
