class Depository < ApplicationRecord
  include Accountable

  SUBTYPES = [
    [ "Checking", "checking" ],
    [ "Savings", "savings" ]
  ].freeze

  class << self
    def display_name
      "Cash"
    end
  end

  def color
    "#875BF7"
  end

  def icon
    "landmark"
  end
end
