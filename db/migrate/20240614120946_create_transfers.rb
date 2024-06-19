class CreateTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :transfers, id: :uuid do |t|
      t.timestamps
    end
  end
end
