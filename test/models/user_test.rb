require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:family_admin)
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

  test "email address is normalized" do
    @user.update!(email: " User@ExAMPle.CoM ")
    assert_equal "user@example.com", @user.reload.email
  end

  test "display name" do
    user = User.new(email: "user@example.com")
    assert_equal "user@example.com", user.display_name
    user.first_name = "Bob"
    assert_equal "Bob", user.display_name
    user.last_name = "Dylan"
    assert_equal "Bob Dylan", user.display_name
  end

  test "initial" do
    user = User.new(email: "user@example.com")
    assert_equal "U", user.initial
    user.first_name = "Bob"
    assert_equal "B", user.initial
    user.first_name = nil
    user.last_name = "Dylan"
    assert_equal "D", user.initial
  end

  test "names are normalized" do
    @user.update!(first_name: "", last_name: "")
    assert_nil @user.first_name
    assert_nil @user.last_name

    @user.update!(first_name: " Bob ", last_name: " Dylan ")
    assert_equal "Bob", @user.first_name
    assert_equal "Dylan", @user.last_name
  end
end
