class CreateAddTagsToTransactions < ActiveRecord::Migration[7.2]
  def change
    add_column :transactions, :tag_ids, :string, array: true, default: []

    create_table :transaction_tags do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :name

      t.timestamps
    end
  end
end
