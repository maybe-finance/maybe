class DailyExchangeRateJob < ApplicationJob
  queue_as :default

  def perform
    app_id = ENV['OPEN_EXCHANGE_APP_ID']

    # Get the last date for which exchange rates were fetched for each currency
    last_fetched_dates = ExchangeRate.group(:base_currency).maximum(:date)

    # Loop through each currency and fetch exchange rates for each
    Currency.all.each do |currency|
      last_fetched_date = last_fetched_dates[currency.iso_code] || Date.yesterday
      next_day = last_fetched_date + 1.day
      response = Faraday.get("https://openexchangerates.org/api/historical/#{next_day}.json") do |req|
        req.params['app_id'] = app_id
        req.params['base'] = currency.iso_code
        req.params['symbols'] = Currency.where.not(iso_code: currency.iso_code).pluck(:iso_code).join(',')
      end

      if response.success?
        rates = JSON.parse(response.body)['rates']

        rates.each do |currency_iso_code, value|
          ExchangeRate.find_or_create_by(date: Date.today, base_currency: currency.iso_code, converted_currency: currency_iso_code) do |exchange_rate|
            exchange_rate.rate = value
          end
          puts "#{currency.iso_code} to #{currency_iso_code} on #{Date.today}: #{value}"
        end
      else
        puts "Failed to fetch exchange rates for #{currency.iso_code} on #{Date.today}: #{response.status}"
      end
    end
  end
end
