class OtherAsset < ApplicationRecord
  include Accountable

  class << self
    def color
      "#12B76A"
    end
  end

  def color
    self.class.color
  end

  def icon
    "plus"
  end
end
