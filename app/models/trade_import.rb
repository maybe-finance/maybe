class TradeImport < Import
  def import!
    transaction do
      mappings.each(&:create_mappable!)

      rows.each do |row|
        account = mappings.accounts.mappable_for(row.account)

        # Try to find or create security with exchange validation
        security = find_or_create_security(
          ticker: row.ticker,
          exchange_operating_mic: row.exchange_operating_mic,
          currency: row.currency.presence || account.currency
        )

        entry = account.entries.build \
          date: row.date_iso,
          amount: row.signed_amount,
          name: row.name,
          currency: row.currency.presence || account.currency,
          entryable: Account::Trade.new(
            security: security,
            qty: row.qty,
            currency: row.currency.presence || account.currency,
            price: row.price
          ),
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
    %i[date ticker exchange_operating_mic currency qty price account name]
  end

  def dry_run
    {
      transactions: rows.count,
      accounts: Import::AccountMapping.for_import(self).creational.count
    }
  end

  def csv_template
    template = <<-CSV
      date*,ticker*,exchange_operating_mic,currency,qty*,price*,account,name
      05/15/2024,AAPL,XNAS,USD,10,150.00,Trading Account,Apple Inc. Purchase
      05/16/2024,GOOGL,XNAS,USD,-5,2500.00,Investment Account,Alphabet Inc. Sale
      05/17/2024,TSLA,XNAS,USD,2,700.50,Retirement Account,Tesla Inc. Purchase
    CSV

    CSV.parse(template, headers: true)
  end

  private

    def find_or_create_security(ticker:, exchange_operating_mic:, currency:)
      # First try to find an existing security
      security = Security.find_by(
        ticker: ticker,
        exchange_operating_mic: exchange_operating_mic
      )

      return security if security.present?

      # Create new security
      security = Security.new(
        ticker: ticker,
        exchange_operating_mic: exchange_operating_mic
      )

      # Only validate with Synth if exchange_operating_mic is provided and Synth is configured
      if exchange_operating_mic.present? && Security.security_prices_provider.present?
        response = Security.security_prices_provider.fetch_security_prices(
          ticker: ticker,
          mic_code: exchange_operating_mic,
          start_date: Date.current,
          end_date: Date.current
        )

        if !response.success?
          raise ImportError, "Unable to validate security #{ticker} on exchange #{exchange_operating_mic}. Prices could not be found."
        end
      end

      # If we get here, either no exchange was provided or validation passed
      security.save!
      security
    end
end
