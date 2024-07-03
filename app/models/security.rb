class Security < ApplicationRecord
  has_many :trades, class_name: "Account::Trade"
end
