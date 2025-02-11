class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[early_access]

  def dashboard
    @period = Period.from_param(params[:period])
    snapshot = Current.family.snapshot(@period)
    @net_worth_series = snapshot[:net_worth_series]
    @asset_series = snapshot[:asset_series]
    @liability_series = snapshot[:liability_series]

    snapshot_transactions = Current.family.snapshot_transactions
    @income_series = snapshot_transactions[:income_series]
    @spending_series = snapshot_transactions[:spending_series]
    @savings_rate_series = snapshot_transactions[:savings_rate_series]

    snapshot_account_transactions = Current.family.snapshot_account_transactions
    @top_spenders = snapshot_account_transactions[:top_spenders]
    @top_earners = snapshot_account_transactions[:top_earners]
    @top_savers = snapshot_account_transactions[:top_savers]

    @accounts = Current.family.accounts.active
    @account_groups = @accounts.by_group(period: @period, currency: Current.family.currency)
    @transactions = Current.family.transactions.limit(6).reverse_chronological.with_default_inclusions

    # TODO: Placeholders for trendlines
    placeholder_series_data = 10.times.map do |i|
      { date: Date.current - i.days, value: Money.new(0, Current.family.currency) }
    end
    @investing_series = TimeSeries.new(placeholder_series_data)
  end

  def changelog
    @release_notes = Provider::Github.new.fetch_latest_release_notes
  end

  def feedback
  end

  def early_access
    redirect_to root_path if self_hosted?

    @invite_codes_count = InviteCode.count
    @invite_code = InviteCode.order("RANDOM()").limit(1).first
    render layout: false
  end
end
