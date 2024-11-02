class LoansController < ApplicationController
  include AccountActions

  permitted_accountable_attributes(
    :id, :rate_type, :interest_rate, :term_months
  )
end
