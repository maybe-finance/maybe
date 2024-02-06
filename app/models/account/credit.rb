class Account::Credit < ApplicationRecord
  include Accountable

  CARD_TYPES = %i[mastercard visa american_express discover].freeze
end
