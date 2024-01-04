class CreateInstitutions < ActiveRecord::Migration[7.1]
  def change
    create_table :institutions, id: :uuid do |t|
      t.string :name
      t.text :logo
      t.string :color
      t.string :url
      t.string :provider
      t.string :provider_id

      t.timestamps
    end

    add_index :institutions, :provider_id, unique: true
  end
end
