class StockExchange < ApplicationRecord
  scope :in_country, ->(country_code) { where(country_code: country_code) }
end
