class Security < ApplicationRecord
  has_many :trades, dependent: :nullify, class_name: "Account::Trade"
end
