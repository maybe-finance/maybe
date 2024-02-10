class PagesController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @asset_groups = AssetGroup.from_accounts(Current.family.accounts)
  end
end
