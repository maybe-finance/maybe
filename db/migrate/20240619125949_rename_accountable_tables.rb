class RenameAccountableTables < ActiveRecord::Migration[7.2]
  def change
    rename_table :account_depositories, :depositories
    rename_table :account_investments, :investments
    rename_table :account_credits, :credit_cards
    rename_table :account_properties, :properties
    rename_table :account_vehicles, :vehicles
    rename_table :account_loans, :loans
    rename_table :account_cryptos, :cryptos
    rename_table :account_other_assets, :other_assets
    rename_table :account_other_liabilities, :other_liabilities

    reversible do |dir|
      dir.up do
        update_accountable_types(
          'Account::Depository' => 'Depository',
          'Account::Investment' => 'Investment',
          'Account::Credit' => 'CreditCard',
          'Account::Property' => 'Property',
          'Account::Vehicle' => 'Vehicle',
          'Account::Loan' => 'Loan',
          'Account::Crypto' => 'Crypto',
          'Account::OtherAsset' => 'OtherAsset',
          'Account::OtherLiability' => 'OtherLiability'
        )

        remove_column :accounts, :classification, :virtual

        change_table :accounts do |t|
          t.virtual(
            :classification,
            type: :string,
            stored: true,
            as: <<-SQL
              CASE
                WHEN accountable_type IN ('Loan', 'CreditCard', 'OtherLiability')
                THEN 'liability'
                ELSE 'asset'
              END
            SQL
          )
        end
      end

      dir.down do
        update_accountable_types(
          'Depository' => 'Account::Depository',
          'Investment' => 'Account::Investment',
          'CreditCard' => 'Account::Credit',
          'Property' => 'Account::Property',
          'Vehicle' => 'Account::Vehicle',
          'Loan' => 'Account::Loan',
          'Crypto' => 'Account::Crypto',
          'OtherAsset' => 'Account::OtherAsset',
          'OtherLiability' => 'Account::OtherLiability'
        )

        remove_column :accounts, :classification, :virtual

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
  end

  private

    def update_accountable_types(mapping)
      Account.reset_column_information

      mapping.each do |old_type, new_type|
        Account.where(accountable_type: old_type).update_all(accountable_type: new_type)
      end
    end
end
