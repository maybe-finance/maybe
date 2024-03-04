namespace :currencies do
  desc "Seed Currencies"
  task seed: :environment do
    currencies = ENV["CURRENCIES"].split(",")

    if currencies.count > 1 && ENV["SYNTH_API_KEY"].present?
      url = "https://api.synthfinance.com/currencies"

      response = Faraday.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{ENV["SYNTH_API_KEY"]}"
      end

      synth_currencies = JSON.parse(response.body)

      currencies.each do |iso_code|
        Currency.find_or_create_by(iso_code: iso_code) do |c|
          c.name = synth_currencies["data"].find { |currency| currency["iso_code"] == iso_code.downcase }["name"]
        end
      end

      puts "Currencies created: #{Currency.count}"
    elsif currencies.count == 1
      Currency.find_or_create_by(iso_code: currencies.first)
    else
      puts "No currencies found in ENV['CURRENCIES']"
    end
  end
end
