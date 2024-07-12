class Money
  include Comparable, Arithmetic
  include ActiveModel::Validations

  class ConversionError < StandardError
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
      exchange_rate = store.find_rate(from: iso_code, to: other_iso_code, date: date)&.rate || fallback_rate

      raise ConversionError.new("Couldn't find exchange rate from #{iso_code} to #{other_iso_code} on #{date}") unless exchange_rate

      Money.new(amount * exchange_rate, other_iso_code)
    end
  end

  def cents_str(precision = currency.default_precision)
    format_str = "%.#{precision}f"
    amount_str = format_str % amount
    parts = amount_str.split(currency.separator)

    if parts.length < 2
      ""
    else
      parts.last.ljust(precision, "0")
    end
  end

  # Use `format` for basic formatting only.
  # Use the Rails number_to_currency helper for more advanced formatting.
  def format
    whole_part, fractional_part = sprintf("%.#{currency.default_precision}f", amount).split(".")
    whole_with_delimiters = whole_part.chars.to_a.reverse.each_slice(3).map(&:join).join(currency.delimiter).reverse
    formatted_amount = "#{whole_with_delimiters}#{currency.separator}#{fractional_part}"

    currency.default_format.gsub("%n", formatted_amount).gsub("%u", currency.symbol)
  end
  alias_method :to_s, :format

  def as_json
    { amount: amount, currency: currency.iso_code }.as_json
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

  def default_format_options
    {
      unit: currency.symbol,
      precision: currency.default_precision,
      delimiter: currency.delimiter,
      separator: currency.separator
    }
  end

  private
    def source_must_be_of_known_type
      unless @source.is_a?(Money) || @source.is_a?(Numeric) || @source.is_a?(BigDecimal)
        errors.add :source, "must be a Money, Numeric, or BigDecimal"
      end
    end
end
