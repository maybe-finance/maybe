class Account::OtherAsset < ApplicationRecord
  include Accountable

  def self.type_name
    "Other Asset"
  end
end
