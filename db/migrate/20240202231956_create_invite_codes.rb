class CreateInviteCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :invite_codes, id: :uuid do |t|
      t.string :code
      t.references :user, null: true, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
