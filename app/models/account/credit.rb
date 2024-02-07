class Account::Credit < ApplicationRecord
  include Accountable
  SUBTYPES = [
    [ "Mastercard", "mastercard" ],
    [ "Visa", "visa" ],
    [ "American Express", "american_express" ],
    [ "Discover", "discover" ]
  ].freeze
end
