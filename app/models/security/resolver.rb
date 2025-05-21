class Security::Resolver
  def initialize(symbol, exchange_operating_mic: nil, country_code: nil)
    @symbol = symbol
    @exchange_operating_mic = exchange_operating_mic
    @country_code = country_code
  end

  def resolve
    return nil unless symbol

    exact_match = Security.find_by(
      ticker: symbol,
      exchange_operating_mic: exchange_operating_mic
    )

    exact_match if exact_match.present?
  end

  private
    attr_reader :symbol, :exchange_operating_mic, :country_code
    
    def fetch_from_provider
      return nil unless Security.provider.present?

      result = Security.search_provider(
        symbol,
        exchange_operating_mic: exchange_operating_mic
      )

      return nil unless result.success?

      selection = if exchange_operating_mic.present?
        result.data.find do |s| 
          s.ticker == symbol && s.exchange_operating_mic == exchange_operating_mic
        end
      else
        result.data.sort_by
      end

      unless selection.present?

      end

      selection
    end

    def 
end
