class SyncSecurityJob < ApplicationJob
  queue_as :default

  def perform(security_id)
    security = Security.find_by(id: security_id)
    return unless security

    profile_data = Faraday.get("https://api.twelvedata.com/profile?symbol=#{security.symbol}&apikey=#{ENV['TWELVEDATA_KEY']}")
    profile_details = JSON.parse(profile_data.body)

    security.update(
      name: profile_details['name'],
      exchange: profile_details['exchange'],
      mic_code: profile_details['mic_code']
    )

    # Pull price history
    earliest_date_connection = Faraday.get("https://api.twelvedata.com/earliest_timestamp?symbol=#{security.symbol}&interval=1day&apikey=#{ENV['TWELVEDATA_KEY']}")

    earliest_date = JSON.parse(earliest_date_connection.body)['datetime']

    prices_connection = Faraday.get("https://api.twelvedata.com/time_series?apikey=#{ENV['TWELVEDATA_KEY']}&interval=1day&symbol=#{security.symbol}&start_date=#{earliest_date}&outputsize=5000")

    prices = JSON.parse(prices_connection.body)['values']

    all_prices = []

    prices.each do |price|
      all_prices << {
        security_id: security.id,
        date: price['datetime'],
        open: price['open'],
        high: price['high'],
        low: price['low'],
        close: price['close'],
      }
    end

    all_prices.uniq! { |price| price[:date] }

    SecurityPrice.upsert_all(all_prices, unique_by: :index_security_prices_on_security_id_and_date)

    security.update(last_synced_at: DateTime.now)
  end
end
