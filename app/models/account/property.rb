class Account::Property < ApplicationRecord
  include Accountable

  def icon
    "icon-real-estate.svg"
  end

  def type_name
    "Real Estate"
  end

  def color
    {
      background: "bg-[#FEF0F7]",
      text: "text-[#F03695]"
    }
  end
end
