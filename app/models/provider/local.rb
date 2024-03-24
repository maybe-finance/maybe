class Provider::Local
  def initialize(...)
  end

  def fetch_exchange_rate(from:, to:, date:)
    Response.new rate: 1.0
  end

  private
    Response = Struct.new(:rate, keyword_init: true)
end
