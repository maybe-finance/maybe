class Security < ApplicationRecord
  before_save :upcase_ticker

  has_many :trades, dependent: :nullify, class_name: "Account::Trade"

  validates :ticker, presence: true, uniqueness: { case_sensitive: false }

  private

    def upcase_ticker
      self.ticker = ticker.upcase
    end
end
