class Accounts::LogosController < ApplicationController
  def show
    @account = Current.family.accounts.find(params[:account_id])
    render_placeholder
  end

  def render_placeholder
    render formats: :svg
  end
end
