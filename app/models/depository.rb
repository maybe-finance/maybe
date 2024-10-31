class Depository < ApplicationRecord
  include Accountable

  def color
    "#875BF7"
  end

  def icon
    "landmark"
  end
end
