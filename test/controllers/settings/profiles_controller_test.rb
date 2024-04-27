require "test_helper"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end
  test "get" do
    get settings_profile_url
    assert_response :success
  end

  test "destroy" do
    delete settings_profile_url
    assert_response :redirect

    assert_raises(ActiveRecord::RecordNotFound) do
      User.find(@user.id)
    end

    assert_enqueued_with(job: DeleteUserJob, args: [@user.attributes])
  end
end
