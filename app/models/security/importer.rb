class Security::Importer
  def initialize(provider, stock_exchange = nil)
    @provider = provider
    @stock_exchange = stock_exchange
  end

  def import
    if @stock_exchange
      securities = @provider.fetch_exchange_tickers(exchange_mic: @stock_exchange)&.tickers
    else
      securities = @provider.fetch_all_tickers&.tickers
    end

    stock_exchanges = StockExchange.where(mic: securities.map { |s| s[:exchange] }).index_by(&:mic)
    existing_securities = Security.where(ticker: securities.map { |s| s[:symbol] }, stock_exchange_id: stock_exchanges.values.map(&:id)).pluck(:ticker, :stock_exchange_id).to_set

    securities_to_create = securities.map do |security|
      stock_exchange_id = stock_exchanges[security[:exchange]]&.id
      next if existing_securities.include?([ security[:symbol], stock_exchange_id ])

      {
        name: security[:name],
        ticker: security[:symbol],
        stock_exchange_id: stock_exchange_id,
        country_code: security[:country_code]
      }
    end.compact

    Security.insert_all(securities_to_create) unless securities_to_create.empty?
  end
end
