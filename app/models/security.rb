class Security < ApplicationRecord
  has_many :holdings, dependent: :destroy
  has_many :portfolios, through: :holdings
  has_many :security_prices, dependent: :destroy
end
