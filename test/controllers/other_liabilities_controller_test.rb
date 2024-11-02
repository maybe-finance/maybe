require "test_helper"

class OtherLiabilitiesControllerTest < ActionDispatch::IntegrationTest
  include AccountActionsInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @accountable = @other_liability = other_liabilities(:one)
  end
end
