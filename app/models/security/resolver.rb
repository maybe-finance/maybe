class Security::Resolver
  def initialize(symbol, exchange_operating_mic: nil, country_code: nil)
    @symbol = symbol
    @exchange_operating_mic = exchange_operating_mic
    @country_code = country_code
  end

  def resolve
  end

  private
    attr_reader :symbol, :exchange_operating_mic, :country_code

    def provider
      Security.provider
    end
end
