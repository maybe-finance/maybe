class CreditCardsController < ApplicationController
  include AccountableResource

  permitted_accountable_attributes(
    :id,
    :available_credit,
    :minimum_payment,
    :apr,
    :annual_fee,
    :expiration_date
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
      # Update credit card-specific attributes
      if account_params[:accountable_attributes].present?
        @account.credit_card.update!(account_params[:accountable_attributes])
      end

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@account), notice: "Credit card account updated" }
        format.turbo_stream { stream_redirect_to account_path(@account), notice: "Credit card account updated" }
      end
    else
      @error_message = result.error || "Unable to update account details."
      render :edit, status: :unprocessable_entity
    end
  end
end
