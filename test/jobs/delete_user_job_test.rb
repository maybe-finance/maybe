require "test_helper"

class DeleteUserJobTest < ActiveJob::TestCase
  setup do
    @user_admin = users(:family_admin)
    @second_admin = users(:other_family_admin)
    @user_member = users(:family_member)
  end

  test "can be enqueued with user" do
    assert_enqueued_with(job: DeleteUserJob, args: [ @user_member ]) do
      DeleteUserJob.perform_later(@user_member)
    end
  end

  test "can be enqueued with admin user" do
    assert_enqueued_with(job: DeleteUserJob, args: [ @user_admin ]) do
      DeleteUserJob.perform_later(@user_admin)
    end
  end

  test "deleting a member just deletes user and related data" do
    DeleteUserJob.perform_now(@user_member)

    assert_raises(ActiveRecord::RecordNotFound) do
      User.find(@user_member.id)
    end
  end

  test "family and related accounts are not deleted when there are other admins" do
    User.where(id: @user_member.id).destroy_all # just making sure the user has been deleted
    DeleteUserJob.perform_now(@user_admin)

    assert_equal Family.where(id: @user_admin.family_id).count, 1

    assert Account.where(family_id: @user_admin.family_id).count > 0
    assert_equal User.where(family_id: @user_admin.family_id).count, 1
  end

  test "family, related accounts and other members are deleted for the last remaining admin" do
    User.where(id: @user_admin.id).destroy_all # just making sure the first admin has been deleted
    User.where(id: @user_member.id).destroy_all # just other members are all gone.
    DeleteUserJob.perform_now(@second_admin)

    assert_raises(ActiveRecord::RecordNotFound) do
      Family.find(@second_admin.family_id)
    end

    assert Account.where(family_id: @user_admin.family_id).count == 0
    assert_equal User.where(family_id: @user_admin.family_id).count, 0
  end
end
