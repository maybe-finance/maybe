class Money
    include Comparable
    attr_reader :amount, :currency

    def initialize(obj, currency = :USD)
        unless obj.is_a?(Money) || obj.is_a?(Numeric) || obj.is_a?(BigDecimal)
            raise ArgumentError, "obj must be an instance of Money, Numeric, or BigDecimal"
        end

        @amount = obj.is_a?(Money) ? obj.amount : obj
        @currency = obj.is_a?(Money) ? obj.currency.to_sym : currency.to_sym
    end

    def cents(precision: nil)
        _precision = precision || CURRENCY_OPTIONS[@currency.to_sym][:precision]
        return "" unless _precision.positive?

        fractional_part = @amount.to_s.split(".")[1] || ""
        fractional_part = fractional_part[0, _precision].ljust(_precision, "0")
    end

    def symbol
        CURRENCY_OPTIONS[@currency.to_sym][:symbol]
    end

    def separator
        CURRENCY_OPTIONS[@currency.to_sym][:separator]
    end

    def precision
        CURRENCY_OPTIONS[@currency.to_sym][:precision]
    end

    def <=>(other)
        return nil unless other.is_a?(Money)
        @amount <=> other.amount
    end

    def +(other)
        raise ArgumentError, "Currency mismatch" unless same_currency?(other)
        Money.new(@amount + other.amount, @currency)
    end

    def -(other)
        raise ArgumentError, "Currency mismatch" unless same_currency?(other)
        Money.new(@amount - other.amount, @currency)
    end

    def *(other)
        if other.is_a?(Money)
            raise ArgumentError, "Currency mismatch" unless same_currency?(other)
            Money.new(@amount * other.amount, @currency)
        else
            Money.new(@amount * BigDecimal(other.to_s), @currency)
        end
    end

    def /(other)
        if other.is_a?(Money)
            raise ArgumentError, "Currency mismatch" unless same_currency?(other)
            @amount / other.amount
        else
            Money.new(@amount / BigDecimal(other.to_s), @currency)
        end
    end

    private
        def same_currency?(other)
            @currency == other.currency
        end
end
