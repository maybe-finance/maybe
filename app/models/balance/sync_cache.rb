class Balance::SyncCache
  def initialize(account)
    @account = account
  end

  def get_valuation(date)
    converted_entries.find { |e| e.date == date && e.valuation? }
  end

  def get_holdings(date)
    converted_holdings.select { |h| h.date == date }
  end

  def get_entries(date)
    converted_entries.select { |e| e.date == date && (e.transaction? || e.trade?) }
  end

  def find_rate_by_cache(amount_money, to_currency, date: Date.current, fallback_rate: 1)
    raise TypeError unless amount_money.respond_to?(:amount) && amount_money.respond_to?(:currency)

    iso_code = Money::Currency.new(amount_money.currency).iso_code
    other_iso_code = Money::Currency.new(to_currency).iso_code

    return amount_money if iso_code == other_iso_code

    exchange_rate = exchange_rates(to_currency)[[ iso_code, date ]]&.last&.rate ||
      ExchangeRate.fetch_rate(from: iso_code, to: other_iso_code, date: date)&.rate ||
      fallback_rate

    raise Money::ConversionError.new(from_currency: iso_code, to_currency: other_iso_code, date: date) unless exchange_rate

    Money.new(amount_money.amount * exchange_rate, other_iso_code)
  end

  private
    attr_reader :account

    def converted_entries
      @converted_entries ||= entries.map do |e|
        converted_entry = e.dup
        converted_entry.amount = find_rate_by_cache(
          converted_entry.amount_money,
          account.currency,
          date: e.date,
        ).amount
        converted_entry.currency = account.currency
        converted_entry
      end
    end

    def converted_holdings
      @converted_holdings ||= holdings.map do |h|
        converted_holding = h.dup
        converted_holding.amount = find_rate_by_cache(
          converted_holding.amount_money,
          account.currency,
          date: h.date,
        ).amount
        converted_holding.currency = account.currency
        converted_holding
      end
    end

    def entries
      @entries ||= account.entries.order(:date).to_a
    end

    def holdings
      @holdings ||= account.holdings
    end

    def exchange_rates(to_currency)
      combined = entries + holdings
      all_dates = combined.map(&:date).uniq
      all_currencies = combined.map(&:currency).uniq

      @exchange_rates ||= ExchangeRate
        .where(from_currency: all_currencies, to_currency: to_currency)
        .where(date: all_dates)
        .order(:date)
        .group_by { |r| [ r.from_currency, r.date.to_date ] }
    end
end
