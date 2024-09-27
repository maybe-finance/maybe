class TradeImport < Import
  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        type: "Import::TradeRow",
        account: row[account_col_label] || "Default Import Account",
        date: row[date_col_label],
        ticker: row[ticker_col_label],
        qty: row[qty_col_label],
        price: row[price_col_label],
        currency: row[currency_col_label] || family.currency,
        name: row[name_col_label] || "Imported trade"
      }
    end

    rows.insert_all!(mapped_rows)
  end

  def publish
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
    %w[accounts]
  end

  def csv_accounts
    rows.map(&:account).reject(&:blank?).uniq
  end

  def csv_valid?
    rows.any? && rows.map(&:valid?).all?
  end

  def configured?
    uploaded? && rows.any?
  end

  def publishable?
    cleaned?
  end

  def csv_template
    template = <<-CSV
      Date*,Qty*,Account,Name,Category,Tags
      2024-01-01,-8.55,Checking,Starbucks,Food & Drink,Tag1|Tag2
      2024-04-15,2000,Savings,Paycheck,Income,
    CSV

    CSV.parse(template, headers: true)
  end
end
