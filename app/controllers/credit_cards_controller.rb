class CreditCardsController < ApplicationController
  include AccountActions

  permitted_accountable_attributes(
    :id,
    :available_credit,
    :minimum_payment,
    :apr,
    :annual_fee,
    :expiration_date
  )
end
