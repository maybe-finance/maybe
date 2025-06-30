require "test_helper"

module AccountableResourceInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "shows new form" do
    Family.any_instance.stubs(:get_link_token).returns("test-link-token")

    get new_polymorphic_url(@account.accountable)
    assert_response :success
  end

  test "shows edit form" do
    get edit_account_url(@account)
    assert_response :success
  end

  test "renders accountable page" do
    get account_url(@account)
    assert_response :success
  end

  test "destroys account" do
    delete account_url(@account)
    assert_redirected_to accounts_path
    assert_enqueued_with job: DestroyJob
    assert_equal "#{@account.accountable_name.underscore.humanize} account scheduled for deletion", flash[:notice]
  end
end
