require "test_helper"
require "ostruct"

class ExchangeRate::ImporterTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @provider = mock
  end

  test "syncs missing rates from provider" do
    ExchangeRate.delete_all

    provider_response = provider_success_response([
      OpenStruct.new(from: "USD", to: "EUR", date: 2.days.ago.to_date, rate: 1.3),
      OpenStruct.new(from: "USD", to: "EUR", date: 1.day.ago.to_date, rate: 1.4),
      OpenStruct.new(from: "USD", to: "EUR", date: Date.current, rate: 1.5)
    ])

    @provider.expects(:fetch_exchange_rates)
             .with(from: "USD", to: "EUR", start_date: get_provider_fetch_start_date(2.days.ago.to_date), end_date: Date.current)
             .returns(provider_response)

    ExchangeRate::Importer.new(
      exchange_rate_provider: @provider,
      from: "USD",
      to: "EUR",
      start_date: 2.days.ago.to_date,
      end_date: Date.current
    ).import_provider_rates

    db_rates = ExchangeRate.where(from_currency: "USD", to_currency: "EUR", date: 2.days.ago.to_date..Date.current)
                           .order(:date)

    assert_equal 3, db_rates.count
    assert_equal 1.3, db_rates[0].rate
    assert_equal 1.4, db_rates[1].rate
    assert_equal 1.5, db_rates[2].rate
  end

  test "syncs diff when some rates already exist" do
    ExchangeRate.delete_all

    # Pre-populate DB with the first two days
    ExchangeRate.create!(from_currency: "USD", to_currency: "EUR", date: 3.days.ago.to_date, rate: 1.2)
    ExchangeRate.create!(from_currency: "USD", to_currency: "EUR", date: 2.days.ago.to_date, rate: 1.25)

    provider_response = provider_success_response([
      OpenStruct.new(from: "USD", to: "EUR", date: 1.day.ago.to_date, rate: 1.3)
    ])

    @provider.expects(:fetch_exchange_rates)
             .with(from: "USD", to: "EUR", start_date: get_provider_fetch_start_date(1.day.ago.to_date), end_date: Date.current)
             .returns(provider_response)

    ExchangeRate::Importer.new(
      exchange_rate_provider: @provider,
      from: "USD",
      to: "EUR",
      start_date: 3.days.ago.to_date,
      end_date: Date.current
    ).import_provider_rates

    db_rates = ExchangeRate.order(:date)
    assert_equal 4, db_rates.count
    assert_equal [ 1.2, 1.25, 1.3, 1.3 ], db_rates.map(&:rate)
  end

  test "no provider calls when all rates exist" do
    ExchangeRate.delete_all

    (3.days.ago.to_date..Date.current).each_with_index do |date, idx|
      ExchangeRate.create!(from_currency: "USD", to_currency: "EUR", date:, rate: 1.2 + idx * 0.01)
    end

    @provider.expects(:fetch_exchange_rates).never

    ExchangeRate::Importer.new(
      exchange_rate_provider: @provider,
      from: "USD",
      to: "EUR",
      start_date: 3.days.ago.to_date,
      end_date: Date.current
    ).import_provider_rates
  end

  # A helpful "reset" option for when we need to refresh provider data
  test "full upsert if clear_cache is true" do
    ExchangeRate.delete_all

    # Seed DB with stale data
    (2.days.ago.to_date..Date.current).each do |date|
      ExchangeRate.create!(from_currency: "USD", to_currency: "EUR", date:, rate: 1.0)
    end

    provider_response = provider_success_response([
      OpenStruct.new(from: "USD", to: "EUR", date: 2.days.ago.to_date, rate: 1.3),
      OpenStruct.new(from: "USD", to: "EUR", date: 1.day.ago.to_date, rate: 1.4),
      OpenStruct.new(from: "USD", to: "EUR", date: Date.current,        rate: 1.5)
    ])

    @provider.expects(:fetch_exchange_rates)
             .with(from: "USD", to: "EUR", start_date: get_provider_fetch_start_date(2.days.ago.to_date), end_date: Date.current)
             .returns(provider_response)

    ExchangeRate::Importer.new(
      exchange_rate_provider: @provider,
      from: "USD",
      to: "EUR",
      start_date: 2.days.ago.to_date,
      end_date: Date.current,
      clear_cache: true
    ).import_provider_rates

    db_rates = ExchangeRate.where(from_currency: "USD", to_currency: "EUR").order(:date)
    assert_equal [ 1.3, 1.4, 1.5 ], db_rates.map(&:rate)
  end

  test "clamps end_date to today when future date is provided" do
    ExchangeRate.delete_all

    future_date = Date.current + 3.days

    provider_response = provider_success_response([
      OpenStruct.new(from: "USD", to: "EUR", date: Date.current, rate: 1.6)
    ])

    @provider.expects(:fetch_exchange_rates)
             .with(from: "USD", to: "EUR", start_date: get_provider_fetch_start_date(Date.current), end_date: Date.current)
             .returns(provider_response)

    ExchangeRate::Importer.new(
      exchange_rate_provider: @provider,
      from: "USD",
      to: "EUR",
      start_date: Date.current,
      end_date: future_date
    ).import_provider_rates

    assert_equal 1, ExchangeRate.count
  end

  private
    def get_provider_fetch_start_date(start_date)
      # We fetch with a 5 day buffer to account for weekends and holidays
      start_date - 5.days
    end
end
