class AccountsController < ApplicationController
  layout "with_sidebar"

  include Filterable
  before_action :set_account, only: %i[ edit show destroy sync update ]

  def index
    @institutions = Current.family.institutions
    @accounts = Current.family.accounts.ungrouped.alphabetically
  end

  def summary
    snapshot = Current.family.snapshot(@period)
    @net_worth_series = snapshot[:net_worth_series]
    @asset_series = snapshot[:asset_series]
    @liability_series = snapshot[:liability_series]
    @accounts = Current.family.accounts
    @account_groups = @accounts.by_group(period: @period, currency: Current.family.currency)
  end

  def list
  end

  def new
    @account = Account.new(
      balance: nil,
      accountable: Accountable.from_type(params[:type])&.new
    )

    if params[:institution_id]
      @account.institution = Current.family.institutions.find_by(id: params[:institution_id])
    end
  end

  def show
    @balance_series = @account.series(period: @period)
  end

  def edit
  end

  def update
    @account.update! account_params.except(:accountable_type)
    redirect_back_or_to account_path(@account), notice: t(".success")
  end

  def create
    @account = Current.family
                      .accounts
                      .create_with_optional_start_balance! \
                        attributes: account_params.except(:start_date, :start_balance),
                        start_date: account_params[:start_date],
                        start_balance: account_params[:start_balance]
    @account.sync_later
    redirect_back_or_to account_path(@account), notice: t(".success")
  rescue ActiveRecord::RecordInvalid => e
    redirect_back_or_to accounts_path, alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    @account.destroy!
    redirect_to accounts_path, notice: t(".success")
  end

  def sync
    unless @account.syncing?
      @account.sync_later
    end

    redirect_to account_path(@account), notice: t(".success")
  end

  def sync_all
    synced_accounts_count = 0
    Current.family.accounts.each do |account|
      next unless account.can_sync?

      account.sync_later
      synced_accounts_count += 1
    end

    if synced_accounts_count > 0
      redirect_back_or_to accounts_path, notice: t(".success", count: synced_accounts_count)
    else
      redirect_back_or_to accounts_path, alert: t(".no_accounts_to_sync")
    end
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :accountable_type, :balance, :start_date, :start_balance, :currency, :subtype, :is_active, :institution_id)
    end
end
