class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[early_access]

  def dashboard
    @period = Period.from_key(params[:period], fallback: true)
    @net_worth_series = Current.family.net_worth_series(@period)
    @accounts = Current.family.accounts.active
  end

  def changelog
    @release_notes = Provider::Github.new.fetch_latest_release_notes

    render layout: "settings"
  end

  def feedback
    render layout: "settings"
  end

  def early_access
    redirect_to root_path if self_hosted?

    @invite_codes_count = InviteCode.count
    @invite_code = InviteCode.order("RANDOM()").limit(1).first
    render layout: false
  end
end
