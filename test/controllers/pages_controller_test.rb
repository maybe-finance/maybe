require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "dashboard" do
    sign_in users(:bob)
    get root_path
    assert_response :ok
  end
end
