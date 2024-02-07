require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "#title(page_title)" do
    title("Test Title")
    assert_equal "Test Title", content_for(:title)
  end

  test "#header_title(page_title)" do
    header_title("Test Header Title")
    assert_equal "Test Header Title", content_for(:header_title)
  end

  test "#permitted_accountable_partial(accountable_type)" do
    assert_equal "account", permitted_accountable_partial("Account")
    assert_equal "user", permitted_accountable_partial("User")
    assert_equal "admin_user", permitted_accountable_partial("AdminUser")
  end
end
