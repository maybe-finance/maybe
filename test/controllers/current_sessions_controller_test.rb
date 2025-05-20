require "test_helper"

class CurrentSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    sign_in @user
  end

  test "can update the preferred tab for any namespace" do
    put current_session_url, params: { current_session: { tab_key: "accounts_sidebar_tab", tab_value: "asset" } }
    assert_response :success
    session = Session.order(updated_at: :desc).first
    assert_equal "asset", session.get_preferred_tab("accounts_sidebar_tab")
  end
end
