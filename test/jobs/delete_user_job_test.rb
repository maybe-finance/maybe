require "test_helper"

class DeleteUserJobTest < ActiveJob::TestCase

  setup do
    @user_admin = users(:family_admin)
    @user_member = users(:family_member)
  end

  test "can be enqueued with user attributes" do
    assert_enqueued_with(job: DeleteUserJob, args: [@user_member.attributes]) do
      DeleteUserJob.perform_later(@user_member.attributes)
    end
  end

  test "can be enqueued with admin user attributes" do
    assert_enqueued_with(job: DeleteUserJob, args: [@user_admin.attributes]) do
      DeleteUserJob.perform_later(@user_admin.attributes)
    end
  end

  test "deleting a member with an admin will not delete the family" do
    DeleteUserJob.perform_now(@user_member.attributes)
    Family.find(@user_member.family_id)
  end

  test "family, related accounts and other members are deleted for the last remaining admin" do
    DeleteUserJob.perform_now(@user_admin.attributes)

    assert_raises(ActiveRecord::RecordNotFound) do
      puts Family.find(@user_admin.family_id)
    end

    assert_raises(ActiveRecord::RecordNotFound) do
      puts Family.find(@user_admin.family_id).accounts
    end

    assert_equal Account.where(family_id: @user_admin.family_id).count, 0
    assert_equal User.where(family_id: @user_admin.family_id).count, 0
  end
end
