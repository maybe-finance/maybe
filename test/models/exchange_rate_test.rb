require "test_helper"

class ExchangeRateTest < ActiveSupport::TestCase
  setup do
    @synth_instance = Provider::Synth.new "foo"
    ExchangeRate.stubs(:exchange_rates_provider).returns(@synth_instance)
  end

  test "exchange rate provider is nil when no api key provided" do
    ExchangeRate.unstub :exchange_rates_provider

    with_env_overrides SYNTH_API_KEY: nil do
      assert_nil ExchangeRate.exchange_rates_provider
    end
  end

  test "exchange rate provider defaults to Synth if api key provided" do
    ExchangeRate.unstub :exchange_rates_provider

    with_env_overrides SYNTH_API_KEY: "foo" do
      assert_instance_of Provider::Synth, ExchangeRate.exchange_rates_provider
    end
  end

  test "searches db for rate prior to calling providers" do
    @synth_instance.expects(:fetch_exchange_rate).never

    assert_equal exchange_rates(:day_29_ago_eur_to_usd),
                 ExchangeRate.find_rate(from: "EUR", to: "USD", date: 29.days.ago.to_date)
  end

  test "fetch rate from provider when it's not found in db" do
    @synth_instance.expects(:fetch_exchange_rate)
                   .with(from: "USD", to: "MXN", date: Date.current)
                   .returns(Provider::Base::ExchangeRateResponse.new(rate: 1.0, success?: true))
                   .times(2)

    assert_no_difference "ExchangeRate.count" do
      ExchangeRate.find_rate from: "USD", to: "MXN", date: Date.current, cache: false
    end

    assert_difference "ExchangeRate.count", 1 do
      ExchangeRate.find_rate from: "USD", to: "MXN", date: Date.current, cache: true
    end
  end

  test "provided rates are saved to the db if cache option set" do
    @synth_instance.expects(:fetch_exchange_rate)
                   .with(from: "USD", to: "MXN", date: Date.current)
                   .returns(Provider::Base::ExchangeRateResponse.new(rate: 1.0, success?: true))

    assert_difference "ExchangeRate.count", 1 do
      ExchangeRate.find_rate from: "USD", to: "MXN", date: Date.current, cache: true
    end
  end

  test "fetches exchange rates from provider for specified period" do
    oldest_usd_eur_rate = ExchangeRate.where(base_currency: "USD", converted_currency: "EUR").order(:date).first

    date_with_missing_usd_eur_rate = oldest_usd_eur_rate.date - 1

    @synth_instance.expects(:fetch_exchange_rate)
                   .with(from: "USD", to: "EUR", date: date_with_missing_usd_eur_rate)
                   .returns(Provider::Base::ExchangeRateResponse.new(rate: 1.0, success?: true))
                   .times(2)

    assert_no_difference "ExchangeRate.count" do
      ExchangeRate.find_rates \
        from: "USD",
        to: "EUR",
        start_date: date_with_missing_usd_eur_rate,
        end_date: oldest_usd_eur_rate.date,
        cache: false
    end

    assert_difference "ExchangeRate.count", 1 do
      ExchangeRate.find_rates \
        from: "USD",
        to: "EUR",
        start_date: date_with_missing_usd_eur_rate,
        end_date: oldest_usd_eur_rate.date,
        cache: true # cache to DB after rate found
    end
  end

  test "returns nil when rate not found" do
    @synth_instance.expects(:fetch_exchange_rate)
                   .with(from: "EUR", to: "GBP", date: 2.days.ago.to_date)
                   .returns(Provider::Base::ExchangeRateResponse.new(success?: false))

    assert_nil ExchangeRate.find_rate(from: "EUR", to: "GBP", date: 2.days.ago.to_date)
  end

  test "returns empty array when rates not found in db and provider disabled" do
    @synth_instance.expects(:fetch_exchange_rate)
                   .with(from: "EUR", to: "GBP", date: 2.days.ago.to_date)
                   .returns(Provider::Base::ExchangeRateResponse.new(success?: false))

    @synth_instance.expects(:fetch_exchange_rate)
                   .with(from: "EUR", to: "GBP", date: 1.day.ago.to_date)
                   .returns(Provider::Base::ExchangeRateResponse.new(success?: false))

    rates = ExchangeRate.find_rates \
      from: "EUR",
      to: "GBP",
      start_date: 2.days.ago.to_date,
      end_date: 1.day.ago.to_date

    assert_equal [], rates
  end
end
