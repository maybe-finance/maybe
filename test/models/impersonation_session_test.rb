require "test_helper"

class ImpersonationSessionTest < ActiveSupport::TestCase
  test "only super admin can impersonate" do
    regular_user = users(:family_member)

    assert_not regular_user.super_admin?

    assert_raises(ActiveRecord::RecordInvalid) do
      ImpersonationSession.create!(
        impersonator: regular_user,
        impersonated: users(:maybe_support_staff)
      )
    end
  end

  test "super admin cannot be impersonated" do
    super_admin = users(:maybe_support_staff)

    assert super_admin.super_admin?

    assert_raises(ActiveRecord::RecordInvalid) do
      ImpersonationSession.create!(
        impersonator: users(:family_member),
        impersonated: super_admin
      )
    end
  end

  test "impersonation session must have different impersonator and impersonated" do
    super_admin = users(:maybe_support_staff)

    assert_raises(ActiveRecord::RecordInvalid) do
      ImpersonationSession.create!(
        impersonator: super_admin,
        impersonated: super_admin
      )
    end
  end
end
