class Depository < ApplicationRecord
  include Accountable

  SUBTYPES = [
    [ "Checking", "checking" ],
    [ "Savings", "savings" ]
  ].freeze

  def color
    "#875BF7"
  end

  def icon
    "landmark"
  end
end
