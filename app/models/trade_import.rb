class TradeImport < Import
  def import!
    transaction do
      rows.each do |row|
        account = family.accounts.find_by(name: row[:account]) || mappings.of_type(Import::AccountMapping).find_by(key: row[:account])&.account

        account.import = self if account.new_record?
        account.save! if account.new_record?

        security = Security.find_or_create_by(ticker: row[:ticker])

        entry = account.entries.build \
          date: normalize_date_str(row[:date]),
          amount: row[:qty].to_d * row[:price].to_d,
          name: row[:name],
          currency: account.currency,
          entryable: Account::Trade.new(security: security, qty: row[:qty], currency: account.currency, price: row[:price]),
          import: self

        entry.save!
      end

      self.status = :complete
      save!
    end
  rescue => error
    self.status = :failed
    save!

    raise error
  end

  def mapping_steps
    [ Import::AccountMapping ]
  end

  def dry_run
    {
      transactions: rows.count,
      accounts: Import::AccountMapping.for_import(self).creational.count
    }
  end

  def csv_template
    template = <<-CSV
      date*,ticker*,qty*,price*,currency,account,name
      05/15/2024,AAPL,10,150.00,USD,Trading Account,Apple Inc. Purchase
      05/16/2024,GOOGL,-5,2500.00,USD,Investment Account,Alphabet Inc. Sale
      05/17/2024,TSLA,2,700.50,USD,Retirement Account,Tesla Inc. Purchase
    CSV

    CSV.parse(template, headers: true)
  end
end
