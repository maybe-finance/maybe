require "test_helper"

class Issue::PricesMissingTest < ActiveSupport::TestCase
  setup do
    @issue = Issue::PricesMissing.new
    @account = Account.new(id: "123abc")
    @issue.issuable = @account
  end

  test "stale? returns false when no prices are found" do
    @issue.append_missing_price("AAPL", (Date.current - 5.days).to_s)

    Security::Price.expects(:find_prices).returns([])
    @account.expects(:owns_ticker?).with("AAPL").returns(true)

    assert_not @issue.stale?
  end

  test "stale? returns true when all expected prices are found" do
    start_date = Date.current - 5.days
    @issue.append_missing_price("AAPL", start_date.to_s)

    expected_prices = (start_date..Date.current).map { |date| { date: date } }
    Security::Price.expects(:find_prices).returns(expected_prices)
    @account.expects(:owns_ticker?).with("AAPL").returns(true)

    assert @issue.stale?
  end

  test "stale? returns false when some prices are missing" do
    start_date = Date.current - 5.days
    @issue.append_missing_price("AAPL", start_date.to_s)

    incomplete_prices = (start_date..Date.current - 2.days).map { |date| { date: date } }
    Security::Price.expects(:find_prices).returns(incomplete_prices)
    @account.expects(:owns_ticker?).with("AAPL").returns(true)

    assert_not @issue.stale?
  end

  test "stale? returns true when the account doesn't own the ticker" do
    @issue.append_missing_price("AAPL", (Date.current - 5.days).to_s)

    @account.expects(:owns_ticker?).with("AAPL").returns(false)

    assert @issue.stale?
  end

  test "stale? handles multiple tickers correctly" do
    @issue.append_missing_price("AAPL", (Date.current - 5.days).to_s)
    @issue.append_missing_price("GOOGL", (Date.current - 3.days).to_s)

    @account.expects(:owns_ticker?).with("AAPL").returns(true)
    @account.expects(:owns_ticker?).with("GOOGL").returns(true)

    Security::Price.expects(:find_prices).with(ticker: "AAPL", start_date: Date.current - 5.days).returns([])
    Security::Price.expects(:find_prices).with(ticker: "GOOGL", start_date: Date.current - 3.days).returns([])

    assert_not @issue.stale?
  end
end
