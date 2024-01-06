class RealTimeSyncJob

  def perform(security_id)
    security = Security.find(security_id)

    return if security.nil?

    prices_connection = Faraday.get("https://api.twelvedata.com/price?apikey=#{ENV['TWELVEDATA_KEY']}&symbol=#{security.symbol}")

    price = JSON.parse(prices_connection.body)['price']

    return if price.nil?

    # Update the security real time price
    security.update(real_time_price: price, real_time_price_updated_at: DateTime.now)
  end
end
