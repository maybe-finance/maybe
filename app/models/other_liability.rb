class OtherLiability < ApplicationRecord
  include Accountable

  class << self
    def color
      "#737373"
    end

    def icon
      "minus"
    end

    def classification
      "liability"
    end
  end
end
