require "test_helper"

class IssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "should get show polymorphically" do
    issues.each do |issue|
      get issue_url(issue)
      assert_response :success
      assert_dom "h2", text: issue.title
      assert_dom "h3", text: "Issue Description"
      assert_dom "h3", text: "How to fix this issue"
    end
  end
end
