class Account::OtherAsset < ApplicationRecord
  include Accountable

  def type_name
    "Other Asset"
  end
end
