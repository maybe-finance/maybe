class AddInviteCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :invite_codes, id: :uuid do |t|
      t.string :code, index: { unique: true }
      t.references :user, null: true, foreign_key: true, type: :uuid, index: true

      t.timestamps
    end
  end
end