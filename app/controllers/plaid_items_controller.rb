class PlaidItemsController < ApplicationController
  before_action :set_plaid_item, only: %i[destroy sync]

  def create
    Current.family.plaid_items.create_from_public_token(
      plaid_item_params[:public_token],
      item_name
    )

    redirect_to accounts_path, notice: t(".success")
  end

  def destroy
    @plaid_item.destroy
    redirect_to accounts_path, notice: "Linked account removed"
  end

  def sync
    # placeholder no-op
  end

  private
    def set_plaid_item
      @plaid_item = Current.family.plaid_items.find(params[:id])
    end

    def plaid_item_params
      params.require(:plaid_item).permit(:public_token, metadata: {})
    end

    def item_name
      plaid_item_params.dig(:metadata, :institution, :name)
    end
end
