namespace :exchange_rates do
  desc 'Fetch exchange rates from openexchangerates.org'
  task sync: :environment do
    # Use Faraday to make a request openexchangerates.org time series endpoint
    # Use the response to create or update exchange rates in the database
    url = 'https://openexchangerates.org/api/time-series.json'
    app_id = ENV['OPEN_EXCHANGE_APP_ID']
    start_date = (Date.today - 120.days).to_s
    end_date = Date.today.to_s

    # Loop through all Currency records and fetch exchange rates for each
    Currency.all.each do |currency|
      start_period = Date.parse(start_date)
      end_period = Date.parse(end_date)

      while start_period < end_period
        current_end_date = [start_period + 30.days, end_period].min

        response = Faraday.get(url) do |req|
          req.params['app_id'] = app_id
          req.params['start'] = start_period.to_s
          req.params['end'] = current_end_date.to_s
          req.params['base'] = currency.iso_code
          req.params['symbols'] = Currency.where.not(iso_code: currency.iso_code).pluck(:iso_code).join(',')
        end

        if response.success?
          rates = JSON.parse(response.body)['rates']

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

