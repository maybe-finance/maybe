require "test_helper"

class Import::NumberSanitizationTest < ActiveSupport::TestCase
  setup do
    @import = imports(:transaction)
  end

  test "sanitizes US/UK/Asia format (1,234.56)" do
    @import.number_format = "1,234.56"

    assert_equal "1234.56", @import.send(:sanitize_number, "1,234.56")
    assert_equal "1234.56", @import.send(:sanitize_number, "$1,234.56")
    assert_equal "1234.56", @import.send(:sanitize_number, "£1,234.56")
    assert_equal "1234.56", @import.send(:sanitize_number, "¥1,234.56")
    assert_equal "-1234.56", @import.send(:sanitize_number, "-1,234.56")
    assert_equal "1234.56", @import.send(:sanitize_number, "1234.56") # No delimiters
    assert_equal "1234567.89", @import.send(:sanitize_number, "1,234,567.89")
  end

  test "sanitizes European format (1.234,56)" do
    @import.number_format = "1.234,56"

    assert_equal "1234.56", @import.send(:sanitize_number, "1.234,56")
    assert_equal "1234.56", @import.send(:sanitize_number, "€1.234,56")
    assert_equal "-1234.56", @import.send(:sanitize_number, "-1.234,56")
    assert_equal "1234567.89", @import.send(:sanitize_number, "1.234.567,89")
  end

  test "sanitizes French/Scandinavian format (1 234,56)" do
    @import.number_format = "1 234,56"

    assert_equal "1234.56", @import.send(:sanitize_number, "1 234,56")
    assert_equal "1234.56", @import.send(:sanitize_number, "€1 234,56")
    assert_equal "-1234.56", @import.send(:sanitize_number, "-1 234,56")
    assert_equal "1234567.89", @import.send(:sanitize_number, "1 234 567,89")
  end

  test "sanitizes zero-decimal currencies like JPY (1,234)" do
    @import.number_format = "1,234"

    assert_equal "1234", @import.send(:sanitize_number, "1,234")
    assert_equal "1234", @import.send(:sanitize_number, "¥1,234")
    assert_equal "-1234", @import.send(:sanitize_number, "-1,234")
    assert_equal "1234567", @import.send(:sanitize_number, "1,234,567")
  end

  test "handles edge cases" do
    @import.number_format = "1,234.56"

    # Nil and empty values
    assert_equal "", @import.send(:sanitize_number, nil)
    assert_equal "", @import.send(:sanitize_number, "")
    assert_equal "", @import.send(:sanitize_number, " ")

    # Non-numeric input
    assert_equal "", @import.send(:sanitize_number, "abc")
    assert_equal "", @import.send(:sanitize_number, "$")
    assert_equal "", @import.send(:sanitize_number, ".")
    assert_equal "", @import.send(:sanitize_number, "-")
    assert_equal "", @import.send(:sanitize_number, "-.")

    # Mixed input with numbers
    assert_equal "42", @import.send(:sanitize_number, "abc42def")
    assert_equal "42.42", @import.send(:sanitize_number, "abc42.42def")

    # Decimal point handling
    assert_equal "0.5", @import.send(:sanitize_number, ".5")
    assert_equal "5.0", @import.send(:sanitize_number, "5.")
    assert_equal "-0.5", @import.send(:sanitize_number, "-.5")
    assert_equal "42.1", @import.send(:sanitize_number, "42.1.2.3")
  end

  test "defaults to US format if number_format is invalid" do
    @import.number_format = "invalid_format"

    assert_equal "1234.56", @import.send(:sanitize_number, "1,234.56")
    assert_equal "-1234.56", @import.send(:sanitize_number, "-1,234.56")
    assert_equal "", @import.send(:sanitize_number, "abc")
  end
end
