class AccountableSparklinesController < ApplicationController
  def show
    @accountable = Accountable.from_type(params[:accountable_type])
    @series = Current.family
                     .accounts
                     .active
                     .where(accountable: @accountable)
                     .balance_series(currency: Current.family.currency, favorable_direction: @accountable.favorable_direction)
  end
end
