class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags, id: :uuid do |t|
      t.string :name
      t.string "color", default: "#e99537", null: false
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
