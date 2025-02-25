class AddRules < ActiveRecord::Migration[7.2]
  def change
    create_table :rules, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid

      t.date :effective_date, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :rule_triggers do |t|
      t.references :rule, null: false, foreign_key: true, type: :uuid

      t.string :trigger_type, null: false
      t.timestamps
    end

    create_table :rule_actions do |t|
      t.references :rule, null: false, foreign_key: true, type: :uuid

      t.string :action_type, null: false
      t.timestamps
    end
  end
end
