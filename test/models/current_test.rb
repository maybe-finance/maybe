require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "family returns user family" do
    user = users(:family_admin)
    Current.session = user.sessions.create!
    assert_equal user.family, Current.family
  end
end
