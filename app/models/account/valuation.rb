class Account::Valuation < ApplicationRecord
  include Account::Entryable

  class << self
    def search(_params)
      all
    end

    def requires_search?(_params)
      false
    end
  end
end
