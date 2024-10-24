class Security::Importer
  def initialize(provider, stock_exchange)
    @provider = provider
    @stock_exchange = stock_exchange
  end

  def import
    provider.fetch_tickers(exchange_mic: stock_exchange.mic)
  end
end
