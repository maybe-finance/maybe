class LoansController < ApplicationController
  include AccountableResource

  permitted_accountable_attributes(
    :id, :rate_type, :interest_rate, :term_months, :initial_balance
  )

  def update
    form = Account::OverviewForm.new(
      account: @account,
      name: account_params[:name],
      currency: account_params[:currency],
      current_balance: account_params[:balance],
      current_cash_balance: @account.depository? ? account_params[:balance] : "0"
    )

    result = form.save

    if result.success?
      # Update loan-specific attributes
      if account_params[:accountable_attributes].present?
        @account.loan.update!(account_params[:accountable_attributes])
      end

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@account), notice: "Loan account updated" }
        format.turbo_stream { stream_redirect_to account_path(@account), notice: "Loan account updated" }
      end
    else
      @error_message = result.error || "Unable to update account details."
      render :edit, status: :unprocessable_entity
    end
  end
end
