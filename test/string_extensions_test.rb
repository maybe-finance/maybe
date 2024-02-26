# test/string_extensions_test.rb
require "test_helper"

class StringExtensionsTest < ActiveSupport::TestCase
  test "#currency_unit returns the currency unit for a given currency code" do
    assert_equal "$", "USD".currency_unit
    assert_equal "€", "EUR".currency_unit
  end

  test "#currency_separator returns the currency separator for a given currency code" do
    assert_equal ".", "USD".currency_separator
    assert_equal ",", "EUR".currency_separator
  end

  test "#cents_part returns the cents part with 2 precisions by default" do
    assert_equal "45", "123.45".cents_part
  end

  test "#cents_part returns the cents part of the string with given precision" do
    assert_equal "", "123".cents_part(precision: 0)
    assert_equal "4", "123.48".cents_part(precision: 1)
    assert_equal "400", "123.4".cents_part(precision: 3)
  end

  test "#cents_part pads the cents part with zeros up to the specified precision" do
    assert_equal "00", "123".cents_part
    assert_equal "40", "123.4".cents_part
  end
end
