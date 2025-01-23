require "test_helper"

class InviteCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.config.app_mode.stubs(:self_hosted?).returns(true)
  end
  test "admin can generate invite codes" do
    sign_in users(:family_admin)

    assert_difference("InviteCode.count") do
      post invite_codes_url, params: {}
    end
  end

  test "non-admin cannot generate invite codes" do
    sign_in users(:family_member)

    assert_raises(StandardError) { post invite_codes_url, params: {} }
  end
end
