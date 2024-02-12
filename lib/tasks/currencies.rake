namespace :currencies do
  desc "Seed Currencies"
  task seed: :environment do
    currencies = ENV["CURRENCIES"].split(",")

    if currencies.count > 1 && ENV["OPEN_EXCHANGE_APP_ID"].present?
      url = "https://openexchangerates.org/api/currencies.json"

      response = Faraday.get(url) do |req|
        req.params["app_id"] = ENV["OPEN_EXCHANGE_APP_ID"]
      end

      oxr_currencies = JSON.parse(response.body)

      currencies.each do |iso_code|
        Currency.find_or_create_by(iso_code: iso_code) do |c|
          c.name = oxr_currencies[iso_code]
        end
      end

      puts "Currencies created: #{Currency.count}"
    elsif currencies.size.positive?
      currencies.each do |iso_code|
        currency_code = iso_code.upcase
        Currency.find_or_create_by(iso_code: currency_code, name: currency_code)
      end
    else
      puts "No currencies found in ENV['CURRENCIES']"
    end
  end
end
