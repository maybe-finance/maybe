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
    # Create an existing AAPL security with no exchange_operating_mic
    aapl = Security.create!(ticker: "AAPL", exchange_operating_mic: nil)

    # We should only hit the provider for GOOGL since AAPL already exists
    Security.expects(:search_provider).with(
      "GOOGL",
      exchange_operating_mic: "XNAS"
    ).returns([
      Security.new(
        ticker: "GOOGL",
        name: "Google Inc.",
        country_code: "US",
        exchange_mic: "XNGS",
        exchange_operating_mic: "XNAS",
        exchange_acronym: "NGS"
      )
    ]).once

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
                      -> { Security.count } => 1,
                      -> { Account.count } => 1 do
      @import.publish
    end

    assert_equal "complete", @import.status

    # Verify the securities were created/updated correctly
    aapl.reload
    assert_nil aapl.exchange_operating_mic

    googl = Security.find_by(ticker: "GOOGL")
    assert_equal "XNAS", googl.exchange_operating_mic
    assert_equal "XNGS", googl.exchange_mic
  end
end
