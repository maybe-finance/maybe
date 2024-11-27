require "test_helper"

class Account::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @entry = account_entries(:transaction)
  end

  test "gets index" do
    get account_entries_path(account_id: @entry.account.id)
    assert_response :success
  end
end
