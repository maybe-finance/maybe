class Account::Depository < ApplicationRecord
  include Accountable

  def icon
    "icon-bank-accounts.svg"
  end

  def type_name
    "Bank Accounts"
  end

  def color
    {
      background: "bg-[#EAF4FF]",
      text: "text-[#3492FB]"
    }
  end
end
