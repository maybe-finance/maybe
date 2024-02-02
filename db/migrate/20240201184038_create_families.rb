class CreateFamilies < ActiveRecord::Migration[7.2]
  def change
    create_table :families, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
  end
end
