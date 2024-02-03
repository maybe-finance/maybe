require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:bob)
    @potential_user = User.new(
                            email: "david@example.com",
                            password: "foobar",
                            first_name: "David",
                            last_name: "Bowie"
                          )
  end

  test "should be valid" do
    assert @user.valid?, @user.errors.full_messages.to_sentence
  end

end
