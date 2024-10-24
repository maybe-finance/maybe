class SecuritiesImportJob < ApplicationJob
  queue_as :default

  def perform(exchange_mic = nil)
    market_stack_client = Provider::Marketstack.new(ENV["MARKETSTACK_API_KEY"])
    importer = Security::Importer.new(market_stack_client, exchange_mic)

    importer.import
  end
end
