require "test_helper"

class CryptosControllerTest < ActionDispatch::IntegrationTest
  include AccountActionsInterfaceTest

  setup do
    sign_in @user = users(:family_admin)
    @accountable = @crypto = cryptos(:one)
  end
end
