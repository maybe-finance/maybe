class OtherAsset < ApplicationRecord
  include Accountable

  def color
    "#12B76A"
  end

  def mode_required?
    false
  end
end
