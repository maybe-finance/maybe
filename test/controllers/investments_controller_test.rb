require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  include AccountActionsInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @accountable = @investment = investments(:one)
  end
end
