require "test_helper"
require "ostruct"

class TradeImportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper, ImportInterfaceTest

  setup do
    @subject = @import = imports(:trade)
    @provider = mock
    Security.stubs(:provider).returns(@provider)
  end

  test "imports trades and accounts" do
    aapl_resolver = mock
    googl_resolver = mock

    Security::Resolver.expects(:new)
                      .with("AAPL", exchange_operating_mic: nil)
                      .returns(aapl_resolver)
                      .once

    Security::Resolver.expects(:new)
                      .with("GOOGL", exchange_operating_mic: "XNAS")
                      .returns(googl_resolver)
                      .once

    aapl = securities(:aapl)
    googl = Security.create!(ticker: "GOOGL", exchange_operating_mic: "XNAS")

    aapl_resolver.stubs(:resolve).returns(aapl)
    googl_resolver.stubs(:resolve).returns(googl)

    import = <<~CSV
      date,ticker,qty,price,currency,account,name,exchange_operating_mic
      01/01/2024,AAPL,10,150.00,USD,TestAccount1,Apple Purchase,
      01/02/2024,GOOGL,5,2500.00,USD,TestAccount1,Google Purchase,XNAS
    CSV

    @import.update!(
      account: accounts(:depository),
      raw_file_str: import,
      date_col_label: "date",
      ticker_col_label: "ticker",
      qty_col_label: "qty",
      price_col_label: "price",
      exchange_operating_mic_col_label: "exchange_operating_mic",
      date_format: "%m/%d/%Y",
      signage_convention: "inflows_positive"
    )

    @import.generate_rows_from_csv

    @import.mappings.create! key: "TestAccount1", create_when_empty: true, type: "Import::AccountMapping"

    @import.reload

    assert_difference -> { Entry.count } => 2,
                      -> { Trade.count } => 2,
                      -> { Account.count } => 1 do
      @import.publish
    end

    assert_equal "complete", @import.status
  end
end
