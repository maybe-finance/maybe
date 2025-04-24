require "test_helper"
require "ostruct"

class MoneyTest < ActiveSupport::TestCase
  test "can create with default currency" do
    value = Money.new(1000)
    assert_equal 1000, value.amount
  end

  test "can create with custom currency" do
    value1 = Money.new(1000, :EUR)
    value2 = Money.new(1000, :eur)
    value3 = Money.new(1000, "eur")
    value4 = Money.new(1000, "EUR")

    assert_equal value1.currency.iso_code, value2.currency.iso_code
    assert_equal value2.currency.iso_code, value3.currency.iso_code
    assert_equal value3.currency.iso_code, value4.currency.iso_code
  end

  test "equality tests amount and currency" do
    assert_equal Money.new(1000), Money.new(1000)
    assert_not_equal Money.new(1000), Money.new(1001)
    assert_not_equal Money.new(1000, :usd), Money.new(1000, :eur)
  end

  test "can compare with zero Numeric" do
    assert_equal Money.new(0), 0
    assert_raises(TypeError) { Money.new(1) == 1 }
  end

  test "can negate" do
    assert_equal (-Money.new(1000)), Money.new(-1000)
  end

  test "can use comparison operators" do
    assert_operator Money.new(1000), :>, Money.new(999)
    assert_operator Money.new(1000), :>=, Money.new(1000)
    assert_operator Money.new(1000), :<, Money.new(1001)
    assert_operator Money.new(1000), :<=, Money.new(1000)
  end

  test "can add and subtract" do
    assert_equal Money.new(1000) + Money.new(1000), Money.new(2000)
    assert_equal Money.new(1000) + 1000, Money.new(2000)
    assert_equal Money.new(1000) - Money.new(1000), Money.new(0)
    assert_equal Money.new(1000) - 1000, Money.new(0)
  end

  test "can multiply" do
    assert_equal Money.new(1000) * 2, Money.new(2000)
    assert_raises(TypeError) { Money.new(1000) * Money.new(2) }
  end

  test "can divide" do
    assert_equal Money.new(1000) / 2, Money.new(500)
    assert_equal Money.new(1000) / Money.new(500), 2
    assert_raise(TypeError) { 1000 / Money.new(2) }
  end

  test "operator order does not matter" do
    assert_equal Money.new(1000) + 1000, 1000 + Money.new(1000)
    assert_equal Money.new(1000) - 1000, 1000 - Money.new(1000)
    assert_equal Money.new(1000) * 2, 2 * Money.new(1000)
  end

  test "can get absolute value" do
    assert_equal Money.new(1000).abs, Money.new(1000)
    assert_equal Money.new(-1000).abs, Money.new(1000)
  end

  test "can test if zero" do
    assert Money.new(0).zero?
    assert_not Money.new(1000).zero?
  end

  test "can test if negative" do
    assert Money.new(-1000).negative?
    assert_not Money.new(1000).negative?
  end

  test "can test if positive" do
    assert Money.new(1000).positive?
    assert_not Money.new(-1000).positive?
  end

  test "can format" do
    assert_equal "$1,000.90", Money.new(1000.899).to_s
    assert_equal "€1,000.12", Money.new(1000.12, :eur).to_s
    assert_equal "€ 1.000,12", Money.new(1000.12, :eur).format(locale: :nl)
  end

  test "can format with abbreviation" do
    # Values below 1000 should be formatted normally
    assert_equal "$500.00", Money.new(500).format(abbreviate: true)
    assert_equal "$999.99", Money.new(999.99).format(abbreviate: true)
    assert_equal "-$500.00", Money.new(-500).format(abbreviate: true)

    assert_equal "$1.0K", Money.new(1000).format(abbreviate: true)
    assert_equal "$1.5K", Money.new(1500).format(abbreviate: true)
    assert_equal "$999.9K", Money.new(999900).format(abbreviate: true)
    assert_equal "-$1.5K", Money.new(-1500).format(abbreviate: true)

    assert_equal "$1.0M", Money.new(1_000_000).format(abbreviate: true)
    assert_equal "$1.5M", Money.new(1_500_000).format(abbreviate: true)
    assert_equal "$999.9M", Money.new(999_900_000).format(abbreviate: true)
    assert_equal "-$1.5M", Money.new(-1_500_000).format(abbreviate: true)

    assert_equal "$1.0B", Money.new(1_000_000_000).format(abbreviate: true)
    assert_equal "$1.5B", Money.new(1_500_000_000).format(abbreviate: true)
    assert_equal "$999.9B", Money.new(999_900_000_000).format(abbreviate: true)
    assert_equal "-$1.5B", Money.new(-1_500_000_000).format(abbreviate: true)

    assert_equal "€1.5M", Money.new(1_500_000, :EUR).format(abbreviate: true)
    assert_equal "£1.5M", Money.new(1_500_000, :GBP).format(abbreviate: true)
    assert_equal "CA$1.5M", Money.new(1_500_000, :CAD).format(abbreviate: true)

    assert_equal "$900.00", Money.new(900).format(abbreviate: true, abbreviate_threshold: 1000)
    assert_equal "$0.9K", Money.new(900).format(abbreviate: true, abbreviate_threshold: 500)
    assert_equal "$0.1K", Money.new(100).format(abbreviate: true, abbreviate_threshold: 50)

    assert_equal "€ 1.5M", Money.new(1_500_000, :EUR).format(abbreviate: true, locale: :nl)
  end

  test "converts currency when rate available" do
    ExchangeRate.expects(:find_or_fetch_rate).returns(OpenStruct.new(rate: 1.2))

    assert_equal Money.new(1000).exchange_to(:eur), Money.new(1000 * 1.2, :eur)
  end

  test "raises when no conversion rate available and no fallback rate provided" do
    ExchangeRate.expects(:find_or_fetch_rate).returns(nil)

    assert_raises Money::ConversionError do
      Money.new(1000).exchange_to(:jpy)
    end
  end

  test "converts currency with a fallback rate" do
    ExchangeRate.expects(:find_or_fetch_rate).returns(nil).twice

    assert_equal 0, Money.new(1000).exchange_to(:jpy, fallback_rate: 0)
    assert_equal Money.new(1000, :jpy), Money.new(1000, :usd).exchange_to(:jpy, fallback_rate: 1)
  end
end
