# test/string_extensions_test.rb
require "test_helper"

class StringExtensionsTest < ActiveSupport::TestCase
  test "#unit returns the currency unit for a given currency code" do
    assert_equal "$", "USD".unit
    assert_equal "€", "EUR".unit
  end

  test "#separator returns the currency separator for a given currency code" do
    assert_equal ".", "USD".separator
    assert_equal ",", "EUR".separator
  end
end
