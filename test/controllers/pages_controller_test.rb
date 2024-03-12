require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "dashboard" do
    get root_path
    assert_response :ok
  end

  test "default currency set" do
    @user.family.update(currency: "EUR")
    get root_path
    assert_equal "EUR", Money.default_currency.iso_code
    assert_response :ok
  end
end
