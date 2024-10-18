class OtherLiability < ApplicationRecord
  include Accountable

  def color
    "#737373"
  end

  def mode_required?
    false
  end
end
