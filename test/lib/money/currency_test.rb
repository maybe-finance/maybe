require "test_helper"

class Money::CurrencyTest < ActiveSupport::TestCase
  setup do
    @currency = Money::Currency.new(:usd)
  end

  test "has many currencies" do
    assert_operator Money::Currency.all.count, :>, 100
  end

  test "can test equality of currencies" do
    assert_equal Money::Currency.new(:usd), Money::Currency.new(:usd)
    assert_not_equal Money::Currency.new(:usd), Money::Currency.new(:eur)
  end

  test "can get metadata about a currency" do
    assert_equal "USD", @currency.iso_code
    assert_equal "United States Dollar", @currency.name
    assert_equal "$", @currency.symbol
    assert_equal 1, @currency.priority
    assert_equal "Cent", @currency.minor_unit
    assert_equal 100, @currency.minor_unit_conversion
    assert_equal 1, @currency.smallest_denomination
    assert_equal ".", @currency.separator
    assert_equal ",", @currency.delimiter
    assert_equal "%u%n", @currency.default_format
    assert_equal 2, @currency.default_precision
  end

  test "can extract cents string from amount" do
    value1 = Money.new(100)
    value2 = Money.new(100.1)
    value3 = Money.new(100.12)
    value4 = Money.new(100.123)
    value5 = Money.new(200, :jpy)

    assert_equal "00", value1.cents_str
    assert_equal "10", value2.cents_str
    assert_equal "12", value3.cents_str
    assert_equal "12", value4.cents_str
    assert_equal "", value5.cents_str

    assert_equal "", value4.cents_str(0)
    assert_equal "1", value4.cents_str(1)
    assert_equal "12", value4.cents_str(2)
    assert_equal "123", value4.cents_str(3)
  end

  test "step returns the smallest value of the currency" do
    assert_equal 0.01, @currency.step
  end
end
