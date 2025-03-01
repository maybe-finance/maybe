class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[early_access]

  def dashboard
    @period = Period.from_key(params[:period], family: Current.family, fallback: true)
    @balance_sheet = Current.family.balance_sheet
    @accounts = Current.family.accounts.active.with_attached_logo

    @breadcrumbs = [ [ "Home", root_path ], [ "Dashboard", nil ] ]
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
