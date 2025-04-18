class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[early_access]
  include Periodable

  def dashboard
    @balance_sheet = Current.family.balance_sheet
    @accounts = Current.family.accounts.active.with_attached_logo

    @breadcrumbs = [ [ "Home", root_path ], [ "Dashboard", nil ] ]
  end

  def changelog
    @release_notes = github_provider.fetch_latest_release_notes

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

  private
    def github_provider
      Provider::Registry.get_provider(:github)
    end
end
