class Account::Trade < ApplicationRecord
  include Account::Entryable

  belongs_to :security

  class << self
    def search(_params)
      all
    end

    def requires_search?(_params)
      false
    end
  end
end
