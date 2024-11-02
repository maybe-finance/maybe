require "test_helper"

class DepositoriesControllerTest < ActionDispatch::IntegrationTest
  include AccountActionsInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @accountable = @depository = depositories(:one)
  end
end
