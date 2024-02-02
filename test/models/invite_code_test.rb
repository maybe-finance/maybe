require "test_helper"

class InviteCodeTest < ActiveSupport::TestCase
  test "claim! destroys the invitation token" do
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

  test "generate! creates a new invitation and returns its token" do
    assert_difference "InviteCode.count", +1 do
      assert_instance_of String, InviteCode.generate!
    end
  end
end
