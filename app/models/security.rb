class Security < ApplicationRecord
  before_save :normalize_identifiers

  has_many :trades, dependent: :nullify, class_name: "Account::Trade"

  validates :isin, presence: true, uniqueness: { case_sensitive: false }

  private

    def normalize_identifiers
      self.isin = isin.upcase
      self.symbol = symbol.upcase
    end
end
