class OtherLiability < ApplicationRecord
  include Accountable

  class << self
    def color
      "#737373"
    end
  end

  def color
    self.class.color
  end

  def icon
    "minus"
  end
end
