require "test_helper"

module EntryableResourceInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "shows new form" do
    get new_polymorphic_url(@entry.entryable)
    assert_response :success
  end

  test "shows editing drawer" do
    get entry_url(@entry)
    assert_response :success
  end

  test "destroys entry" do
    assert_difference "Entry.count", -1 do
      delete entry_url(@entry)
    end

    assert_enqueued_with job: SyncJob

    assert_redirected_to account_url(@entry.account)
  end
end
