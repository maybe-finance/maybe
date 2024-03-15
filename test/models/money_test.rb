require "test_helper"

class MoneyTest < ActiveSupport::TestCase
    test "#symbol returns the currency symbol for a given currency code" do
        assert_equal "$", Money.new(0, "USD").symbol
        assert_equal "€", Money.new(0, "EUR").symbol
    end

    test "#separator returns the currency separator for a given currency code" do
        assert_equal ".", Money.new(0, "USD").separator
        assert_equal ",", Money.new(0, "EUR").separator
    end

    test "#precision returns the currency's precision for a given currency code" do
        assert_equal 2, Money.new(0, "USD").precision
        assert_equal 0, Money.new(123.45, "KRW").precision
    end

    test "#cents returns the cents part with 2 precisions by default" do
        assert_equal "45", Money.new(123.45, "USD").cents
    end

    test "#cents returns empty when precision is 0" do
        assert_equal "", Money.new(123.45, "USD").cents(precision: 0)
    end

    test "#cents returns the cents part of the string with given precision" do
        amount = Money.new(123.4862, "USD")
        assert_equal "4", amount.cents(precision: 1)
        assert_equal "486", amount.cents(precision: 3)
    end

    test "#cents pads the cents part with zeros up to the specified precision" do
        amount_without_decimal = Money.new(123, "USD")
        amount_with_decimal = Money.new(123.4, "USD")

        assert_equal "00", amount_without_decimal.cents
        assert_equal "40", amount_with_decimal.cents
    end

    test "works with BigDecimal" do
        amount = Money.new(BigDecimal("123.45"), "USD")
        assert_equal "45", amount.cents
    end

    test "can compare two Money objects" do
        amount1 = Money.new(123.45, "USD")
        amount2 = Money.new(123.45, "USD")
        amount3 = Money.new(123.46, "USD")

        assert_equal amount1, amount2
        assert_not_equal amount1, amount3
        assert amount1 < amount3
        assert amount3 > amount1
    end

    test "can do math" do
        amount1 = Money.new(123.45, "USD")
        amount2 = Money.new(123.45, "USD")
        amount3 = Money.new(123.46, "USD")

        assert_equal Money.new(246.90, "USD"), amount1 + amount2
        assert_equal Money.new(0, "USD"), amount1 - amount2
        assert_equal Money.new(370.35, "USD"), amount1 * 3
        assert_equal Money.new(61.73, "USD"), amount3 / 2
    end
end
