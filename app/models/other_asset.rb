class OtherAsset < ApplicationRecord
  include Accountable

  class << self
    def color
      "#12B76A"
    end

    def icon
      "plus"
    end

    def classification
      "asset"
    end
  end
end
