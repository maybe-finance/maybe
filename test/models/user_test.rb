require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not save user without email" do
    user = User.new(password: 'password123', password_confirmation: 'password123')
    assert_not user.save, "Saved the user without an email"
  end

  test "should not save user without password" do
    user = User.new(email: 'test@example.com')
    assert_not user.save
  end

  test "should save user with email and password" do
    user = User.new(email: 'test@example.com', password: 'password123', password_confirmation: 'password123')
    assert user.save
  end

  test "should not save user without password confirmation" do
    user = User.new(password: 'password123', password_confirmation: '')
    assert_not user.save, "Saved the user without a password confirmation"
  end

  test "should not save user with mismatched password and password confirmation" do
    user = User.new(password: 'password123', password_confirmation: 'password321')
    assert_not user.save, "Saved the user with mismatched password and password confirmation"
  end

  test "should not save user with password shorter than 8 characters" do
    user = User.new(password: 'passwor', password_confirmation: 'passwor')
    assert_not user.save, "Saved the user with password shorter than 8 characters"
  end
end
