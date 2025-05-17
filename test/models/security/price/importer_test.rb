require "test_helper"
require "ostruct"

class Security::Price::ImporterTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @provider = mock
    @security = Security.create!(ticker: "AAPL")
  end

  test "syncs missing prices from provider" do
    Security::Price.delete_all

    provider_response = provider_success_response([
      OpenStruct.new(security: @security, date: 2.days.ago.to_date, price: 150, currency: "USD"),
      OpenStruct.new(security: @security, date: 1.day.ago.to_date, price: 155, currency: "USD"),
      OpenStruct.new(security: @security, date: Date.current, price: 160, currency: "USD")
    ])

    @provider.expects(:fetch_security_prices)
             .with(symbol: @security.ticker, exchange_operating_mic: @security.exchange_operating_mic,
                   start_date: get_provider_fetch_start_date(2.days.ago.to_date), end_date: Date.current)
             .returns(provider_response)

    Security::Price::Importer.new(
      security: @security,
      security_provider: @provider,
      start_date: 2.days.ago.to_date,
      end_date: Date.current
    ).import_provider_prices

    db_prices = Security::Price.where(security: @security, date: 2.days.ago.to_date..Date.current).order(:date)

    assert_equal 3, db_prices.count
    assert_equal [ 150, 155, 160 ], db_prices.map(&:price)
  end

  test "syncs diff when some prices already exist" do
    Security::Price.delete_all

    # Pre-populate DB with first two days
    Security::Price.create!(security: @security, date: 3.days.ago.to_date, price: 140, currency: "USD")
    Security::Price.create!(security: @security, date: 2.days.ago.to_date, price: 145, currency: "USD")

    provider_response = provider_success_response([
      OpenStruct.new(security: @security, date: 1.day.ago.to_date, price: 150, currency: "USD")
    ])

    @provider.expects(:fetch_security_prices)
             .with(symbol: @security.ticker, exchange_operating_mic: @security.exchange_operating_mic,
                   start_date: get_provider_fetch_start_date(1.day.ago.to_date), end_date: Date.current)
             .returns(provider_response)

    Security::Price::Importer.new(
      security: @security,
      security_provider: @provider,
      start_date: 3.days.ago.to_date,
      end_date: Date.current
    ).import_provider_prices

    db_prices = Security::Price.where(security: @security).order(:date)
    assert_equal 4, db_prices.count
    assert_equal [ 140, 145, 150, 150 ], db_prices.map(&:price)
  end

  test "no provider calls when all prices exist" do
    Security::Price.delete_all

    (3.days.ago.to_date..Date.current).each_with_index do |date, idx|
      Security::Price.create!(security: @security, date:, price: 100 + idx, currency: "USD")
    end

    @provider.expects(:fetch_security_prices).never

    Security::Price::Importer.new(
      security: @security,
      security_provider: @provider,
      start_date: 3.days.ago.to_date,
      end_date: Date.current
    ).import_provider_prices
  end

  test "full upsert if clear_cache is true" do
    Security::Price.delete_all

    # Seed DB with stale prices
    (2.days.ago.to_date..Date.current).each do |date|
      Security::Price.create!(security: @security, date:, price: 100, currency: "USD")
    end

    provider_response = provider_success_response([
      OpenStruct.new(security: @security, date: 2.days.ago.to_date, price: 150, currency: "USD"),
      OpenStruct.new(security: @security, date: 1.day.ago.to_date, price: 155, currency: "USD"),
      OpenStruct.new(security: @security, date: Date.current,        price: 160, currency: "USD")
    ])

    @provider.expects(:fetch_security_prices)
             .with(symbol: @security.ticker, exchange_operating_mic: @security.exchange_operating_mic,
                   start_date: get_provider_fetch_start_date(2.days.ago.to_date), end_date: Date.current)
             .returns(provider_response)

    Security::Price::Importer.new(
      security: @security,
      security_provider: @provider,
      start_date: 2.days.ago.to_date,
      end_date: Date.current,
      clear_cache: true
    ).import_provider_prices

    db_prices = Security::Price.where(security: @security).order(:date)
    assert_equal [ 150, 155, 160 ], db_prices.map(&:price)
  end

  test "clamps end_date to today when future date is provided" do
    Security::Price.delete_all

    future_date = Date.current + 3.days

    provider_response = provider_success_response([
      OpenStruct.new(security: @security, date: Date.current, price: 165, currency: "USD")
    ])

    @provider.expects(:fetch_security_prices)
             .with(symbol: @security.ticker, exchange_operating_mic: @security.exchange_operating_mic,
                   start_date: get_provider_fetch_start_date(Date.current), end_date: Date.current)
             .returns(provider_response)

    Security::Price::Importer.new(
      security: @security,
      security_provider: @provider,
      start_date: Date.current,
      end_date: future_date
    ).import_provider_prices

    assert_equal 1, Security::Price.count
  end

  private
    def get_provider_fetch_start_date(start_date)
      start_date - 5.days
    end
end
