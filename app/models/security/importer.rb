class Security::Importer
  def initialize(provider, stock_exchange = nil)
    @provider = provider
    @stock_exchange = stock_exchange
  end

  def import
    securities = @provider.fetch_tickers(exchange_mic: @stock_exchange)&.tickers

    # Deduplicate securities based on ticker and exchange_mic
    securities_to_create = securities
      .map do |security|
        {
          name: security[:name],
          ticker: security[:symbol],
          country_code: security[:country_code],
          exchange_mic: security[:exchange_mic],
          exchange_acronym: security[:exchange_acronym]
        }
      end
      .compact
      .uniq { |security| [ security[:ticker], security[:exchange_mic] ] }

    # First update any existing securities that only have a ticker
    Security.where(exchange_mic: nil)
      .where(ticker: securities_to_create.map { |s| s[:ticker] })
      .update_all(
        securities_to_create.map do |security|
          {
            name: security[:name],
            country_code: security[:country_code],
            exchange_mic: security[:exchange_mic],
            exchange_acronym: security[:exchange_acronym]
          }
        end.first
      )

    # Then create/update any remaining securities
    Security.upsert_all(
      securities_to_create,
      unique_by: [ :ticker, :exchange_mic ],
      update_only: [ :name, :country_code, :exchange_acronym ]
    ) unless securities_to_create.empty?
  end
end
