class CreateFamilyExports < ActiveRecord::Migration[7.2]
  def change
    create_table :family_exports, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :status, default: "pending", null: false

      t.timestamps
    end
  end
end
