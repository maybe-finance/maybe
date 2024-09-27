class AccountImport < Import
  def import!
    transaction do
      rows.each do |row|
        accountable = mappings.of_type(Import::AccountTypeMapping).find_by(key: row.entity_type)&.accountable

        account = family.accounts.build(
          name: row.name,
          balance: row.amount,
          currency: row.currency,
          accountable: accountable,
          import: self
        )

        account.save!
      end

      self.status = :complete
      save!
    end
  end

  def mapping_steps
    [ Import::AccountTypeMapping ]
  end

  def dry_run
    {
      accounts: rows.count
    }
  end

  def csv_template
    template = <<-CSV
      Account type*,Name*,Balance*,Currency
      Checking,Main Checking Account,1000.00,USD
      Savings,Emergency Fund,5000.00,USD
      Credit Card,Rewards Card,-500.00,USD
    CSV

    CSV.parse(template, headers: true)
  end
end
