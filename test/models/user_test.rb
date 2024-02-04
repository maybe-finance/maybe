require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:bob)
  end

  test "should be valid" do
    assert @user.valid?, @user.errors.full_messages.to_sentence
  end

  # email
  test "email must be present" do
    potential_user = User.new(
      email: "david@davidbowie.com",
      password_digest: BCrypt::Password.create("password"),
      first_name: "David",
      last_name: "Bowie"
    )
    potential_user.email = "     "
    assert_not potential_user.valid?
  end

  test "has email address" do
    assert_equal "bob@bobdylan.com", @user.email
  end

  test "can update email" do
    @user.update(email: "new_email@example.com")
    assert_equal "new_email@example.com", @user.email
  end

  test "email addresses must be unique" do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email addresses are be saved as lower-case" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end
end
