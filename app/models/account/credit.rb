class Account::Credit < ApplicationRecord
  include Accountable

  def icon
    "icon-credit-card.svg"
  end

  def type_name
    "Credit Card"
  end

  def color
    {
      background: "bg-[#E6F6FA]",
      text: "text-[#189FC7]"
    }
  end
end
