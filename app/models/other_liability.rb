class OtherLiability < ApplicationRecord
  include Accountable

  def color
    "#737373"
  end

  def icon
    "minus"
  end
end
