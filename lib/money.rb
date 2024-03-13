class Money
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

    def default_format_options
        {
            unit: @currency.symbol,
            precision: @currency.default_precision,
            delimiter: @currency.delimiter,
            separator: @currency.separator
        }
    end
end
