class CreateChangeLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :change_logs, id: :uuid do |t|
      t.string :record_type
      t.uuid :record_id
      t.string :attribute_name
      t.decimal :old_value, precision: 36, scale: 18
      t.decimal :new_value, precision: 36, scale: 18

      t.timestamps
    end
  end
end
