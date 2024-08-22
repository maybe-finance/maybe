class CreateAddresses < ActiveRecord::Migration[7.2]
  def change
    create_table :addresses, id: :uuid do |t|
      t.references :addressable, type: :uuid, polymorphic: true
      t.string :line1
      t.string :line2
      t.string :county
      t.string :locality
      t.string :region
      t.string :country
      t.integer :postal_code

      t.timestamps
    end
  end
end
