require "test_helper"

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

    test "can compare equality" do
        assert_equal Money.new(1000), Money.new(1000)
    end
end
