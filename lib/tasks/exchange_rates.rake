require "bigdecimal"

namespace :exchange_rates do
  desc "Fetch exchange rates from openexchangerates.org"
  task sync: :environment do
    app_id = ENV["OPEN_EXCHANGE_APP_ID"]
    MININUM_DATE_RANGE = 30.days
    MAXIMUM_DATE_RANGE = 120.days

    # First, check what plan the user is on at OXR
    # If the user is on the Developer plan, we can only fetch exchange rates for the past 30 days and must use the historical endpoint
    account_check = Faraday.get("https://openexchangerates.org/api/usage.json") do |req|
      req.params["app_id"] = app_id
    end
    account_details = JSON.parse(account_check.body)
    quota_limit = account_details["data"]["usage"]["requests_quota"]

    if quota_limit <= 10000
      # First loop through all Currency records and fetch exchange rates for each, but use the historical endpoint, which only allows fetching one day at a time. For each currency, set the base currency to the currency's iso_code and the symbols to all other currencies' iso_codes
      Currency.all.each do |currency|
        (Date.today - MININUM_DATE_RANGE).upto(Date.today) do |date|
          response = Faraday.get("https://openexchangerates.org/api/historical/#{date}.json") do |req|
            req.params["app_id"] = app_id
            req.params["base"] = currency.iso_code
            req.params["symbols"] = Currency.where.not(iso_code: currency.iso_code).pluck(:iso_code).join(",")
          end

          if response.success?
            rates = JSON.parse(response.body)["rates"]

            rates.each do |currency_iso_code, value|
              ExchangeRate.find_or_create_by(date: date, base_currency: currency.iso_code, converted_currency: currency_iso_code) do |exchange_rate|
                exchange_rate.rate = value
              end
              puts "#{currency.iso_code} to #{currency_iso_code} on #{date}: #{value}"
            end
          else
            puts "Failed to fetch exchange rates for #{currency.iso_code} on #{date}: #{response.status}"
          end
        end
      end
    else
      # Use Faraday to make a request openexchangerates.org time series endpoint
      # Use the response to create or update exchange rates in the database
      url = "https://openexchangerates.org/api/time-series.json"
      start_date = (Date.today - MAXIMUM_DATE_RANGE).to_s
      end_date = Date.today.to_s

      # Loop through all Currency records and fetch exchange rates for each
      Currency.all.each do |currency|
        start_period = Date.parse(start_date)
        end_period = Date.parse(end_date)

        while start_period < end_period
          current_end_date = [ start_period + 30.days, end_period ].min

          response = Faraday.get(url) do |req|
            req.params["app_id"] = app_id
            req.params["start"] = start_period.to_s
            req.params["end"] = current_end_date.to_s
            req.params["base"] = currency.iso_code
            req.params["symbols"] = Currency.where.not(iso_code: currency.iso_code).pluck(:iso_code).join(",")
          end

          if response.success?
            rates = JSON.parse(response.body)["rates"]

            rates.each do |date, rate|
              rate.each do |currency_iso_code, value|
                ExchangeRate.find_or_create_by(date: date, base_currency: currency.iso_code, converted_currency: currency_iso_code) do |exchange_rate|
                  exchange_rate.rate = value
                end
                puts "#{currency.iso_code} to #{currency_iso_code} on #{date}: #{value}"
              end
            end
          else
            puts "Failed to fetch exchange rates for period #{start_period} to #{current_end_date}: #{response.status}"
          end

          start_period = current_end_date + 1.day
        end
      end
    end
  end

  desc "Fetch exchange rates from https://github.com/ismartcoding/currency-api"
  task sync_from_ismartcoding: :environment do
    # Exchange rate data is simply stored as JSON files in a repository:
    # https://raw.githubusercontent.com/ismartcoding/currency-api/main/{yyyy-mm-dd}/{24h hour}.json
    FIRST_DATE = "2023-10-10" # First date that has completed data
    DEFAULT_HOUR = "23" # Reference hour of the day to take exchange rates from
    PRECISION = 6 # 6 decimal places
    NDIGITS = 9 + PRECISION # ndigits for millions and enough decimal places
    Date.parse(FIRST_DATE).upto(Date.today) do |date|
      response = Faraday.get("https://raw.githubusercontent.com/ismartcoding/currency-api/main/#{date.iso8601}/#{DEFAULT_HOUR}.json")
      if response.success?
        rates = JSON.parse(response.body)
        # Given base currency, compute other currencies rates in relation to the base (USD).
        # Rate values have 6 decimal places.
        rates_in_usd = rates["quotes"]
        rates_in_usd["USD"] = 1.0 # Add itself so we can compute other rates
        based_rates = { "USD" => rates_in_usd }
        rates_in_usd.each do |currency_iso_code, value_in_usd|
          based_rates[currency_iso_code] = rates_in_usd.transform_values do |other_currency_value|
            (BigDecimal(other_currency_value, NDIGITS) / BigDecimal(value_in_usd, NDIGITS)).round(PRECISION).to_f
          end
        end

        # Now store the exchange rates in the database
        Currency.all.each do |currency|
          based_rates[currency.iso_code].each do |currency_iso_code, value|
            ExchangeRate.find_or_create_by(date: date, base_currency: currency.iso_code, converted_currency: currency_iso_code) do |exchange_rate|
              exchange_rate.rate = value
            end
            puts "#{currency.iso_code} to #{currency_iso_code} on #{date}: #{value}"
          end
        end
      else
        puts "Failed to fetch exchange rates for #{currency.iso_code} on #{date}: #{response.status}"
      end
    end
  end
end
