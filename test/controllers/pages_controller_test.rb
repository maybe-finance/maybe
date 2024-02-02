require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    skip "Pending"
  end

  test "should get index" do
    get pages_index_url
    assert_response :success
  end
end
