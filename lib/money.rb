class Money
  include Comparable, Arithmetic, Formatting
  include ActiveModel::Validations

  class ConversionError < StandardError
    attr_reader :from_currency, :to_currency, :date

    def initialize(from_currency:, to_currency:, date:)
      @from_currency = from_currency
      @to_currency = to_currency
      @date = date

      error_message = message || "Couldn't find exchange rate from #{from_currency} to #{to_currency} on #{date}"

      super(error_message)
    end
  end

  attr_reader :amount, :currency, :store

  validate :source_must_be_of_known_type

  class << self
    def default_currency
      @default ||= Money::Currency.new(:usd)
    end

    def default_currency=(object)
      @default = Money::Currency.new(object)
    end
  end

  def initialize(obj, currency = Money.default_currency, store: ExchangeRate)
    @source = obj
    @amount = obj.is_a?(Money) ? obj.amount : BigDecimal(obj.to_s)
    @currency = obj.is_a?(Money) ? obj.currency : Money::Currency.new(currency)
    @store = store

    validate!
  end

  def exchange_to(other_currency, date: Date.current, fallback_rate: nil)
    iso_code = currency.iso_code
    other_iso_code = Money::Currency.new(other_currency).iso_code

    if iso_code == other_iso_code
      self
    else
      exchange_rate = store.find_or_fetch_rate(from: iso_code, to: other_iso_code, date: date)&.rate || fallback_rate

      raise ConversionError.new(from_currency: iso_code, to_currency: other_iso_code, date: date) unless exchange_rate

      Money.new(amount * exchange_rate, other_iso_code)
    end
  end

  def as_json
    { amount: amount, currency: currency.iso_code, formatted: format }.as_json
  end

  def <=>(other)
    raise TypeError, "Money can only be compared with other Money objects except for 0" unless other.is_a?(Money) || other.eql?(0)

    if other.is_a?(Numeric)
      amount <=> other
    else
      amount_comparison = amount <=> other.amount

      if amount_comparison == 0
        currency <=> other.currency
      else
        amount_comparison
      end
    end
  end

  private
    def source_must_be_of_known_type
      unless @source.is_a?(Money) || @source.is_a?(Numeric) || @source.is_a?(BigDecimal)
        errors.add :source, "must be a Money, Numeric, or BigDecimal"
      end
    end
end
