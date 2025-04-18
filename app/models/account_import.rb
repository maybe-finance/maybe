class AccountImport < Import
  def import!
    transaction do
      rows.each do |row|
        mapping = mappings.account_types.find_by(key: row.entity_type)
        accountable_class = mapping.value.constantize

        account = family.accounts.build(
          name: row.name,
          balance: row.amount.to_d,
          currency: row.currency,
          accountable: accountable_class.new,
          import: self
        )

        account.save!

        account.entries.create!(
          amount: row.amount,
          currency: row.currency,
          date: Date.current,
          name: "Imported account value",
          entryable: Valuation.new
        )
      end
    end
  end

  def mapping_steps
    [ Import::AccountTypeMapping ]
  end

  def required_column_keys
    %i[name amount]
  end

  def column_keys
    %i[entity_type name amount currency]
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
