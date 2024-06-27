class Account::EntriesController < ApplicationController
  layout "with_sidebar"

  before_action :set_entry, only: %i[ edit update show destroy ]

  def index
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
    @entry.update! entry_params
    @entry.sync_account_later

    redirect_back_or_to account_entry_path(@account, @entry), notice: t(".success")
  end

  def show
  end

  def destroy
    @entry.destroy!
    @entry.sync_account_later
    redirect_back_or_to account_url(@entry.account), notice: t(".success")
  end

  private

    def set_entry
      @entry = Current.family.entries.find(params[:id])
      @account = @entry.account
    end

    def permitted_entryable_attributes
      entryable_type = @entry ? @entry.entryable_class.to_s : params[:account_entry][:entryable_type]

      case entryable_type
      when "Account::Transaction"
        [ :id, :notes, :excluded, :category_id, :merchant_id, tag_ids: [] ]
      else
        [ :id ]
      end
    end

    def entry_params
      params.require(:account_entry).permit(:name, :date, :amount, :currency, :entryable_type, entryable_attributes: permitted_entryable_attributes)
    end
end
