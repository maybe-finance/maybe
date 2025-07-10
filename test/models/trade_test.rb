require "test_helper"

class TradeTest < ActiveSupport::TestCase
  test "build_name generates buy trade name" do
    name = Trade.build_name("buy", 10, "AAPL")
    assert_equal "Buy 10.0 shares of AAPL", name
  end

  test "build_name generates sell trade name" do
    name = Trade.build_name("sell", 5, "MSFT")
    assert_equal "Sell 5.0 shares of MSFT", name
  end

  test "build_name handles absolute value for negative quantities" do
    name = Trade.build_name("sell", -5, "GOOGL")
    assert_equal "Sell 5.0 shares of GOOGL", name
  end

  test "build_name handles decimal quantities" do
    name = Trade.build_name("buy", 0.25, "BTC")
    assert_equal "Buy 0.25 shares of BTC", name
  end
end
