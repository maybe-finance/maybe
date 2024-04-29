require "test_helper"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_member)
  end
  test "get" do
    get settings_profile_url
    assert_response :success
  end

  test "can delete a member user" do
    delete settings_profile_url
    assert_response :redirect

    assert User.find(@user.id).marked_for_deletion == true
    assert_enqueued_with(job: DeleteUserJob, args: [ @user ])
  end

  test "can delete an admin as long as other admins exist for family" do
    sign_in @admin = users(:family_admin)

    delete settings_profile_url
    assert_response :redirect

    assert User.find(@admin.id).marked_for_deletion == true
    assert_enqueued_with(job: DeleteUserJob, args: [ @admin ])
  end

  test "cannot delete admin while other members are present" do
    other_admin = users(:other_family_admin)
    User.where.not(id: other_admin.id).destroy_all # just delete other admin so this is last
    
    sign_in @admin = other_admin

    delete settings_profile_url
    assert_response :redirect

    assert User.find(@admin.id).marked_for_deletion == true
  end
end
