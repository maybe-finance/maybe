require "test_helper"

class ValuationsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get valuations_create_url
    assert_response :success
  end

  test "should get show" do
    get valuations_show_url
    assert_response :success
  end

  test "should get update" do
    get valuations_update_url
    assert_response :success
  end

  test "should get destroy" do
    get valuations_destroy_url
    assert_response :success
  end

  test "should get edit" do
    get valuations_edit_url
    assert_response :success
  end

  test "should get new" do
    get valuations_new_url
    assert_response :success
  end
end
