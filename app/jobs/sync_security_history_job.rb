class SyncSecurityHistoryJob

  def perform(security_id)
    security = Security.find(security_id)

    return if security.nil?

    earliest_date_connection = Faraday.get("https://api.twelvedata.com/earliest_timestamp?symbol=#{security.symbol}&interval=1day&apikey=#{ENV['TWELVEDATA_KEY']}")

    earliest_date = JSON.parse(earliest_date_connection.body)['datetime']

    prices_connection = Faraday.get("https://api.twelvedata.com/time_series?apikey=#{ENV['TWELVEDATA_KEY']}&interval=1day&symbol=#{security.symbol}&start_date=#{earliest_date}&outputsize=5000")

    prices = JSON.parse(prices_connection.body)['values']

    return if prices.nil?

    meta = JSON.parse(prices_connection.body)['meta']
    currency = meta['currency'] || 'USD'
    exchange = meta['exchange'] || nil
    kind = meta['type'] || nil

    all_prices = []

    prices.each do |price|
      all_prices << {
        security_id: security.id,
        date: price['datetime'],
        open: price['open'],
        high: price['high'],
        low: price['low'],
        close: price['close'],
        currency: currency,
        exchange: exchange,
        kind: kind
      }
    end

    # remove duplicate dates
    all_prices.uniq! { |price| price[:date] }

    SecurityPrice.upsert_all(all_prices, unique_by: :index_security_prices_on_security_id_and_date)

    security.update(last_synced_at: DateTime.now)
  end
end
