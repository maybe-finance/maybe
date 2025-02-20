class TradeImport < Import
  def import!
    transaction do
      mappings.each(&:create_mappable!)

      rows.each do |row|
        account = mappings.accounts.mappable_for(row.account)

        # Try to find or create security with ticker only
        security = find_or_create_security(
          ticker: row.ticker,
          exchange_operating_mic: row.exchange_operating_mic
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
    def find_or_create_security(ticker:, exchange_operating_mic:)
      # Normalize empty string to nil for consistency
      exchange_operating_mic = nil if exchange_operating_mic.blank?

      # First try to find an exact match in our DB
      internal_security = Security.find_by(ticker:, exchange_operating_mic:)
      return internal_security if internal_security.present?

      # If no exact match and no exchange_operating_mic was provided, try to find any security with the same ticker
      if exchange_operating_mic.nil?
        internal_security = Security.where(ticker:).first
        if internal_security.present?
          internal_security.update!(exchange_operating_mic: nil)
          return internal_security
        end
      end

      # If we couldn't find the security locally and the provider isn't available, create with provided info
      return Security.create!(ticker: ticker, exchange_operating_mic: exchange_operating_mic) unless Security.security_prices_provider.present?

      # Cache provider responses so that when we're looping through rows and importing, we only hit our provider for the unique combinations of ticker / exchange_operating_mic
      cache_key = [ ticker, exchange_operating_mic ]

      @provider_securities_cache ||= {}

      provider_security = @provider_securities_cache[cache_key] ||= begin
        response = Security.security_prices_provider.search_securities(
          query: ticker,
          exchange_operating_mic: exchange_operating_mic
        )

        return nil unless response.success?

        response.securities.first
      end

      return Security.create!(ticker: ticker, exchange_operating_mic: exchange_operating_mic) if provider_security.nil?

      # Create a new security with the provider's data and our exchange_operating_mic
      Security.create!(
        ticker: ticker,
        name: provider_security.dig(:name),
        country_code: provider_security.dig(:country_code),
        logo_url: provider_security.dig(:logo_url),
        exchange_acronym: provider_security.dig(:exchange_acronym),
        exchange_mic: provider_security.dig(:exchange_mic),
        exchange_operating_mic: exchange_operating_mic
      )
    end
end
