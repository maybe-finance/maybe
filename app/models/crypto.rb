class Crypto < ApplicationRecord
  include Accountable

  class << self
    def color
      "#737373"
    end

    def classification
      "asset"
    end

    def icon
      "bitcoin"
    end

    def display_name
      "Crypto"
    end
  end
end
