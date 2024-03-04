class AddClassificationToAccounts < ActiveRecord::Migration[7.2]
  def change
    change_table :accounts do |t|
      t.virtual(
        :classification,
        type: :string,
        stored: true,
        as: <<-SQL
          CASE
            WHEN accountable_type IN ('Account::Loan', 'Account::Credit', 'Account::OtherLiability')
            THEN 'liability'
            ELSE 'asset'
          END
        SQL
      )
    end
  end
end
