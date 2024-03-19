class Money
    include Comparable
    include Arithmetic

    attr_reader :amount, :currency

    class << self
        def default_currency
            @default ||= Money::Currency.new(:usd)
        end

        def default_currency=(object)
            @default = Money::Currency.new(object)
        end
    end

    def initialize(obj, currency = Money.default_currency)
        unless obj.is_a?(Money) || obj.is_a?(Numeric) || obj.is_a?(BigDecimal)
            raise ArgumentError, "obj must be an instance of Money, Numeric, or BigDecimal"
        end

        @amount = obj.is_a?(Money) ? obj.amount : BigDecimal(obj.to_s)
        @currency = obj.is_a?(Money) ? obj.currency : Money::Currency.new(currency)
    end

    def cents_str(precision = @currency.default_precision)
        format_str = "%.#{precision}f"
        amount_str = format_str % @amount
        parts = amount_str.split(@currency.separator)

        return "" if parts.length < 2

        parts.last.ljust(precision, "0")
    end

    # Basic formatting only.  Use the Rails number_to_currency helper for more advanced formatting.
    alias to_s format
    def format
        whole_part, fractional_part = sprintf("%.#{@currency.default_precision}f", @amount).split(".")
        whole_with_delimiters = whole_part.chars.to_a.reverse.each_slice(3).map(&:join).join(@currency.delimiter).reverse
        formatted_amount = "#{whole_with_delimiters}#{@currency.separator}#{fractional_part}"
        @currency.default_format.gsub("%n", formatted_amount).gsub("%u", @currency.symbol)
    end

    def to_json(*_args)
        { amount: @amount, currency: @currency.iso_code }.to_json
    end

    def <=>(other)
        raise TypeError, "Money can only be compared with other Money objects except for 0" unless other.is_a?(Money) || other.eql?(0)
        return @amount <=> other if other.is_a?(Numeric)
        amount_comparison = @amount <=> other.amount
        return amount_comparison unless amount_comparison == 0
        @currency <=> other.currency
    end

    def default_format_options
        {
            unit: @currency.symbol,
            precision: @currency.default_precision,
            delimiter: @currency.delimiter,
            separator: @currency.separator
        }
    end
end
