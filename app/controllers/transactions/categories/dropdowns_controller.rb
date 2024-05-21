class Transactions::Categories::DropdownsController < ApplicationController
  def new
    @transaction = Transaction.find(params[:id])
  end
end
