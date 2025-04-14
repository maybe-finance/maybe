class LoansController < ApplicationController
  include AccountableResource

  permitted_accountable_attributes(
    :id, :rate_type, :interest_rate, :term_months, :initial_balance
  )
end
