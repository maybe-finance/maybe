class Security::Resolver
  def initialize(symbol, exchange_operating_mic: nil, country_code: nil)
    @symbol = validate_symbol!(symbol)
    @exchange_operating_mic = exchange_operating_mic
    @country_code = country_code
  end

  # Attempts several paths to resolve a security:
  # 1. Exact match in DB
  # 2. Search provider for an exact match
  # 3. Search provider for close match, ranked by relevance
  # 4. Create offline security if no match is found in either DB or provider
  def resolve
    return nil if symbol.blank?

    exact_match_from_db ||
      exact_match_from_provider ||
      close_match_from_provider ||
      offline_security
  end

  private
    attr_reader :symbol, :exchange_operating_mic, :country_code

    def validate_symbol!(symbol)
      raise ArgumentError, "Symbol is required and cannot be blank" if symbol.blank?
      symbol.strip.upcase
    end

    def offline_security
      security = Security.find_or_initialize_by(
        ticker: symbol,
        exchange_operating_mic: exchange_operating_mic,
      )

      security.assign_attributes(
        country_code: country_code,
        offline: true # This tells us that we shouldn't try to fetch prices later
      )

      security.save!

      security
    end

    def exact_match_from_db
      Security.find_by(
        {
          ticker: symbol,
          exchange_operating_mic: exchange_operating_mic,
          country_code: country_code.presence
        }.compact
      )
    end

    # If provided a ticker + exchange (and optionally, a country code), we can find exact matches
    def exact_match_from_provider
      # Without an exchange, we can never know if we have an exact match
      return nil unless exchange_operating_mic.present?

      match = provider_search_result.find do |s|
        ticker_matches = s.ticker.upcase.to_s == symbol.upcase.to_s
        exchange_matches = s.exchange_operating_mic.upcase.to_s == exchange_operating_mic.upcase.to_s

        if country_code && exchange_operating_mic
          ticker_matches && exchange_matches && s.country_code.upcase.to_s == country_code.upcase.to_s
        else
          ticker_matches && exchange_matches
        end
      end

      return nil unless match

      find_or_create_provider_match!(match)
    end

    def close_match_from_provider
      filtered_candidates = provider_search_result

      # If a country code is specified, we MUST find a match with the same code
      if country_code.present?
        filtered_candidates = filtered_candidates.select { |s| s.country_code.upcase.to_s == country_code.upcase.to_s }
      end

      # 1. Prefer exact exchange_operating_mic matches (if one was provided)
      # 2. Rank by country relevance (lower index in the list is more relevant)
      # 3. Rank by exchange_operating_mic relevance (lower index in the list is more relevant)
      sorted_candidates = filtered_candidates.sort_by do |s|
        [
          exchange_operating_mic.present? && s.exchange_operating_mic.upcase.to_s == exchange_operating_mic.upcase.to_s ? 0 : 1,
          sorted_country_codes_by_relevance.index(s.country_code&.upcase.to_s) || sorted_country_codes_by_relevance.length,
          sorted_exchange_operating_mics_by_relevance.index(s.exchange_operating_mic&.upcase.to_s) || sorted_exchange_operating_mics_by_relevance.length
        ]
      end

      match = sorted_candidates.first

      return nil unless match

      find_or_create_provider_match!(match)
    end

    def find_or_create_provider_match!(match)
      security = Security.find_or_initialize_by(
        ticker: match.ticker,
        exchange_operating_mic: match.exchange_operating_mic,
      )

      security.country_code = match.country_code
      security.save!

      security
    end

    def provider_search_result
      params = {
        exchange_operating_mic: exchange_operating_mic,
        country_code: country_code
      }.compact_blank

      @provider_search_result ||= Security.search_provider(symbol, **params)
    end

    # Non-exhaustive list of common country codes for help in choosing "close" matches
    # These are generally sorted by market cap.
    def sorted_country_codes_by_relevance
      %w[US CN JP IN GB CA FR DE CH SA TW AU NL SE KR IE ES AE IT HK BR DK SG MX RU IL ID BE TH NO]
    end

    # Non-exhaustive list of common exchange operating MICs for help in choosing "close" matches
    # This is very US-centric since our prices provider and user base is a majority US-based
    def sorted_exchange_operating_mics_by_relevance
      [
        "XNYS",  # New York Stock Exchange
        "XNAS",  # NASDAQ Stock Market
        "XOTC",  # OTC Markets Group (OTC Link)
        "OTCM",  # OTC Markets Group
        "OTCN",  # OTC Bulletin Board
        "OTCI",  # OTC International
        "OPRA",  # Options Price Reporting Authority
        "MEMX",  # Members Exchange
        "IEXA",  # IEX All-Market
        "IEXG",  # IEX Growth Market
        "EDXM",  # Cboe EDGX Exchange (Equities)
        "XCME",  # CME Group (Derivatives)
        "XCBT",  # Chicago Board of Trade
        "XPUS",  # Nasdaq PSX (U.S.)
        "XPSE",  # Nasdaq PHLX (U.S.)
        "XTRD",  # Nasdaq TRF (Trade Reporting Facility)
        "XTXD",  # FINRA TRACE (Trade Reporting)
        "XARC",  # NYSE Arca
        "XBOX",  # BOX Options Exchange
        "XBXO"  # BZX Options (Cboe)
      ]
    end
end
