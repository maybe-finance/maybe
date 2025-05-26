require "test_helper"

class Account::ChartableTest < ActiveSupport::TestCase
  test "generates series and memoizes" do
    account = accounts(:depository)

    test_series = mock
    builder1 = mock
    builder2 = mock

    Balance::ChartSeriesBuilder.expects(:new)
      .with(
        account_ids: [ account.id ],
        currency: account.currency,
        period: Period.last_30_days,
        favorable_direction: account.favorable_direction,
        interval: nil
      )
      .returns(builder1)
      .once

    Balance::ChartSeriesBuilder.expects(:new)
      .with(
        account_ids: [ account.id ],
        currency: account.currency,
        period: Period.last_90_days, # Period changed, so memoization should be invalidated
        favorable_direction: account.favorable_direction,
        interval: nil
      )
      .returns(builder2)
      .once

    builder1.expects(:balance_series).returns(test_series).twice
    series1 = account.balance_series
    memoized_series1 = account.balance_series

    builder2.expects(:balance_series).returns(test_series).twice
    builder2.expects(:cash_balance_series).returns(test_series).once
    builder2.expects(:holdings_balance_series).returns(test_series).once

    series2 = account.balance_series(period: Period.last_90_days)
    memoized_series2 = account.balance_series(period: Period.last_90_days)
    memoized_series2_cash_view = account.balance_series(period: Period.last_90_days, view: :cash_balance)
    memoized_series2_holdings_view = account.balance_series(period: Period.last_90_days, view: :holdings_balance)
  end
end
