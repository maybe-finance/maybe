require "test_helper"

class DeleteUserJobTest < ActiveJob::TestCase

  setup do
    @user_admin = users(:family_admin)
    @user_member = users(:family_member)
  end

  test "can be enqueued with user attributes" do
    assert_enqueued_with(job: DeleteUserJob, args: [@user_admin.attributes]) do
      DeleteUserJob.perform_later(@user_admin.attributes)
    end
  end
end
