class OtherAsset < ApplicationRecord
  include Accountable

  def color
    "#12B76A"
  end

  def icon
    "plus"
  end
end
