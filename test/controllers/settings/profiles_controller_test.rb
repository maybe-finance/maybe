require "test_helper"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
  end

  test "get" do
    get settings_profile_url
    assert_response :success
  end

  test "member can deactivate their account" do
    sign_in @member = users(:family_member)
    delete settings_profile_url

    assert_redirected_to root_url

    assert_not User.find(@member.id).active?
    assert_enqueued_with(job: UserPurgeJob, args: [ @member ])
  end

  test "admin prevented from deactivating when other users are present" do
    sign_in @admin = users(:family_admin)
    delete settings_profile_url

    assert_redirected_to settings_profile_url
    assert_equal "Admin cannot delete account while other users are present. Please delete all members first.", flash[:alert]
    assert_no_enqueued_jobs only: UserPurgeJob
    assert User.find(@admin.id).active?
  end

  test "admin can deactivate their account when they are the last user in the family" do
    sign_in @admin = users(:family_admin)
    users(:family_member).destroy

    delete settings_profile_url

    assert_redirected_to root_url
    assert_not User.find(@admin.id).active?
    assert_enqueued_with(job: UserPurgeJob, args: [ @admin ])
  end
end
