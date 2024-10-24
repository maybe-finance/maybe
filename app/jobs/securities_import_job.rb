class SecuritiesImportJob < ApplicationJob
  queue_as :default

  def perform(country_code = nil)
    exchanges = StockExchange.in_country(country_code)
    market_stack_client = Provider::Marketstack.new(ENV["MARKETSTACK_API_KEY"])

    exchanges.each do |exchange|
      importer = Security::Importer.new(market_stack_client, exchange.mic)
      importer.import
    end
  end
end
