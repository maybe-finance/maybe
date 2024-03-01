class Money
    attr_reader :amount, :currency

    def self.from_amount(amount, currency = "USD")
        Money.new(amount, currency)
    end

    def initialize(amount, currency = :USD)
        @amount = amount
        @currency = currency
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
end
