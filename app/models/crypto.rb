class Crypto < ApplicationRecord
  include Accountable

  def color
    "#737373"
  end

  def icon
    "bitcoin"
  end
end
