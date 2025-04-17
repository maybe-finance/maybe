require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "can print a formatted address" do
    address = Address.new(
      line1: "123 Main St",
      locality: "San Francisco",
      region: "CA",
      country: "US",
      postal_code: "94101"
    )

    assert_equal "123 Main St, San Francisco, CA 94101 US", address.to_s
  end

  test "can print a formatted address with line2" do
    address = Address.new(
      line1: "123 Main St",
      line2: "Apt 1",
      locality: "San Francisco",
      region: "CA",
      country: "US",
      postal_code: "94101"
    )

    assert_equal "123 Main St Apt 1, San Francisco, CA 94101 US", address.to_s
  end

  test "can print empty when address is empty" do
    address = Address.new(
      line1: nil,
      line2: nil,
      locality: nil,
      region: nil,
      country: nil,
      postal_code: nil
    )

    assert_equal "", address.to_s
  end

  test "can strip extras commas and spaces" do
    address = Address.new(
      line1: "123 Main St ,",
      locality: " San Francisco, ",
    )

    assert_equal "123 Main St, San Francisco", address.to_s
  end
end
