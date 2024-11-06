class PlaidItemsController < ApplicationController
  def create
    puts plaid_item_params[:metadata]
    request = Plaid::ItemPublicTokenExchangeRequest.new(
      public_token: plaid_item_params[:public_token]
    )

    response = plaid.item_public_token_exchange(request)

    Current.family.plaid_items.create!(item_access_token: response.access_token)

    redirect_to accounts_path, notice: t(".success")
  end

  private
    def plaid_item_params
      params.require(:plaid_item).permit(:public_token, :metadata)
    end
end
