class CreateFamilies < ActiveRecord::Migration[7.1]
  def change
    create_table :families, id: :uuid do |t|
      t.string :name, null: true
      t.timestamps
    end
  end
end
