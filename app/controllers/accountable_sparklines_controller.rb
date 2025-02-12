class AccountableSparklinesController < ApplicationController
  def show
    @accountable = Accountable.from_type(params[:accountable_type])
    @series = @accountable.series(Current.family)
  end
end
