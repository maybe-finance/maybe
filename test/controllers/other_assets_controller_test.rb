require "test_helper"

class OtherAssetsControllerTest < ActionDispatch::IntegrationTest
  include AccountActionsInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @accountable = @other_asset = other_assets(:one)
  end
end
