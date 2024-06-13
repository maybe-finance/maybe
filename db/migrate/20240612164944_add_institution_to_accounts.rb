class AddInstitutionToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_reference :accounts, :institution, foreign_key: true, type: :uuid
  end
end
