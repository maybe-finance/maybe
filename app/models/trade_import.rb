class TradeImport < Import
  def import!
    transaction do
      mappings.each(&:create_mappable!)

      rows.each do |row|
        account = mappings.accounts.mappable_for(row.account)
        security = Security.find_or_create_by(ticker: row.ticker)

        entry = account.entries.build \
          date: row.date_iso,
          amount: row.signed_amount,
          name: row.name,
          currency: row.currency,
          entryable: Account::Trade.new(security: security, qty: row.qty, currency: row.currency, price: row.price),
          import: self

        entry.save!
      end
    end
  end

  def mapping_steps
    [ Import::AccountMapping ]
  end

  def required_column_keys
    %i[date ticker qty price]
  end

  def column_keys
    %i[date ticker qty price currency account name]
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
