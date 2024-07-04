class Security::Price < ApplicationRecord
  include Syncable

  class << self
    def sync(scope, start_date: nil)
      required_prices = scope.required_securities_prices
      Syncable::Response.new(success?: true)
    end
  end
end
