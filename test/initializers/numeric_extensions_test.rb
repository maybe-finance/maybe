# test/initializers/big_decimal_extensions_test.rb
require "test_helper"

class NumericExtensionsTest < ActiveSupport::TestCase
  test "#cents returns the cents part with 2 precisions by default" do
    amount = 123.45
    assert_equal "45", amount.cents
  end

  test "#cents returns empty when precision is 0" do
    amount = 123.45
    assert_equal "", amount.cents(precision: 0)
  end

  test "#cents returns the cents part of the string with given precision" do
    amount = 123.4862
    assert_equal "4", amount.cents(precision: 1)
    assert_equal "486", amount.cents(precision: 3)
  end

  test "#cents pads the cents part with zeros up to the specified precision" do
    amount_without_decimal = 123
    amount_with_decimal = 123.4

    assert_equal "00", amount_without_decimal.cents
    assert_equal "40", amount_with_decimal.cents
  end
end
