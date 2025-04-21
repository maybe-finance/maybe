require "test_helper"

class Settings::ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:family_admin)
    @member = users(:family_member)
  end

  test "should get show" do
    sign_in @admin
    get settings_profile_path
    assert_response :success
  end

  test "admin can remove a family member" do
    sign_in @admin
    assert_difference("User.count", -1) do
      delete settings_profile_path(user_id: @member)
    end

    assert_redirected_to settings_profile_path
    assert_equal "Member removed successfully.", flash[:notice]
    assert_raises(ActiveRecord::RecordNotFound) { User.find(@member.id) }
  end

  test "admin cannot remove themselves" do
    sign_in @admin
    assert_no_difference("User.count") do
      delete settings_profile_path(user_id: @admin)
    end

    assert_redirected_to settings_profile_path
    assert_equal I18n.t("settings.profiles.destroy.cannot_remove_self"), flash[:alert]
    assert User.find(@admin.id)
  end

  test "non-admin cannot remove members" do
    sign_in @member
    assert_no_difference("User.count") do
      delete settings_profile_path(user_id: @admin)
    end

    assert_redirected_to settings_profile_path
    assert_equal I18n.t("settings.profiles.destroy.not_authorized"), flash[:alert]
    assert User.find(@admin.id)
  end

  test "admin removing a family member also destroys their invitation" do
    # Create an invitation for the member
    invitation = @admin.family.invitations.create!(
      email: @member.email,
      role: "member",
      inviter: @admin
    )

    sign_in @admin

    assert_difference [ "User.count", "Invitation.count" ], -1 do
      delete settings_profile_path(user_id: @member)
    end

    assert_redirected_to settings_profile_path
    assert_equal "Member removed successfully.", flash[:notice]
    assert_raises(ActiveRecord::RecordNotFound) { User.find(@member.id) }
    assert_raises(ActiveRecord::RecordNotFound) { Invitation.find(invitation.id) }
  end
end
