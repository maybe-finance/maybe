require "test_helper"

class InviteCodeTest < ActiveSupport::TestCase
  test "claim! destroys the invite token" do
    code = InviteCode.generate!

    assert_difference "InviteCode.count", -1 do
      InviteCode.claim! code
    end
  end

  test "claim! returns true if valid" do
    assert InviteCode.claim!(InviteCode.generate!)
  end

  test "claim! is falsy if invalid" do
    assert_not InviteCode.claim!("invalid")
  end

  test "generate! creates a new invite and returns its token" do
    assert_difference "InviteCode.count", +1 do
      assert_equal InviteCode.generate!, InviteCode.last.token
    end
  end
end
