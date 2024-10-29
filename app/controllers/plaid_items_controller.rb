class PlaidItemsController < ApplicationController
  def create
    request = Plaid::ItemPublicTokenExchangeRequest.new
    request.public_token = plaid_item_params[:public_token]

    response = plaid.item_public_token_exchange(request)

    # Current.family.plaid_items.create!(item_access_token: response.access_token)

    render json: { status: :ok }
  end

  private
    def plaid_item_params
      params.require(:plaid_item).permit(:public_token, metadata: {})
    end
end
