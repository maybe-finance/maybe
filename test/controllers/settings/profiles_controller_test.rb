require "test_helper"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_member)
  end
  test "get" do
    get settings_profile_url
    assert_response :success
  end

  test "cannot delete admin while other members are present" do
    sign_in @admin = users(:family_admin)

    delete settings_profile_url
    assert_response :redirect

    assert User.find(@admin.id).marked_for_deletion == false
  end

  test "deleting a user will mark the user for deletion and queue a deletion job" do
    delete settings_profile_url
    assert_response :redirect

    assert User.find(@user.id).marked_for_deletion
    assert_enqueued_with(job: DeleteUserJob, args: [@user])
  end
end
