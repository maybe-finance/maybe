class CreateFlipperTables < ActiveRecord::Migration[7.2]
  def up
    create_table :flipper_features do |t|
      t.string :key, null: false
      t.timestamps null: false
    end
    add_index :flipper_features, :key, unique: true

    create_table :flipper_gates do |t|
      t.string :feature_key, null: false
      t.string :key, null: false
      t.text :value
      t.timestamps null: false
    end
    add_index :flipper_gates, [ :feature_key, :key, :value ], unique: true, length: { value: 255 }
  end

  def down
    drop_table :flipper_gates
    drop_table :flipper_features
  end
end
