class Security::Price < ApplicationRecord
  include Provided

  before_save :upcase_ticker

  validates :ticker, presence: true, uniqueness: { scope: :date, case_sensitive: false }

  private

    def upcase_ticker
      self.ticker = ticker.upcase
    end
end
