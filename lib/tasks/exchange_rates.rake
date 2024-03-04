namespace :exchange_rates do
  desc "Fetch exchange rates from Synth API"
  task sync: :environment do
    Currency.all.each do |currency|
      (Date.today - 30.days).upto(Date.today) do |date|
        response = Faraday.get("https://api.synthfinance.com/rates/historical") do |req|
          req.headers["Authorization"] = "Bearer #{ENV["SYNTH_API_KEY"]}"
          req.params["date"] = date.to_s
          req.params["from"] = currency.iso_code
          req.params["to"] = Currency.where.not(iso_code: currency.iso_code).pluck(:iso_code).join(",")
        end

        if response.success?
          rates = JSON.parse(response.body)["data"]["rates"]

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
  end
end
