require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "family returns user family" do
    user = users(:bob)
    Current.user = user
    assert_equal user.family, Current.family
  end
end
