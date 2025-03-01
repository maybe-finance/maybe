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

      # First try to find an exact match in our DB, or if no exchange_operating_mic is provided, find by ticker only
      internal_security = if exchange_operating_mic.present?
        Security.find_by(ticker:, exchange_operating_mic:)
      else
        Security.find_by(ticker:)
      end

      return internal_security if internal_security.present?

      # If security prices provider isn't properly configured or available, create with nil exchange_operating_mic
      return Security.find_or_create_by!(ticker: ticker, exchange_operating_mic: nil) unless Security.provider.present?

      # Cache provider responses so that when we're looping through rows and importing,
      # we only hit our provider for the unique combinations of ticker / exchange_operating_mic
      cache_key = [ ticker, exchange_operating_mic ]
      @provider_securities_cache ||= {}

      provider_security = @provider_securities_cache[cache_key] ||= begin
        Security.search_provider(
          query: ticker,
          exchange_operating_mic: exchange_operating_mic
        ).first
      end

      return Security.find_or_create_by!(ticker: ticker, exchange_operating_mic: nil) if provider_security.nil?

      Security.find_or_create_by!(ticker: provider_security[:ticker], exchange_operating_mic: provider_security[:exchange_operating_mic]) do |security|
        security.name = provider_security[:name]
        security.country_code = provider_security[:country_code]
        security.logo_url = provider_security[:logo_url]
        security.exchange_acronym = provider_security[:exchange_acronym]
        security.exchange_mic = provider_security[:exchange_mic]
      end
    end
end
