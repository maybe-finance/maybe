class Security < ApplicationRecord
  has_many :trades, class_name: "Account::Trade"

  class << self
    def sync(syncable, start_date)
      required_prices = syncable.required_securities_prices
      puts "syncing securities prices"
    end
  end
end
