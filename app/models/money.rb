class Money
    attr_reader :amount, :currency

    CURRENCY_OPTIONS = {
        "USD": { symbol: "$", precision: 2, delimiter: ",", separator: "." },
        "EUR": { symbol: "€", precision: 2, delimiter: ".", separator: "," },
        "GBP": { symbol: "£", precision: 2, delimiter: ",", separator: "." },
        "CAD": { symbol: "C$", precision: 2, delimiter: ",", separator: "." },
        "MXN": { symbol: "MX$", precision: 2, delimiter: ",", separator: "." },
        "HKD": { symbol: "HK$", precision: 2, delimiter: ",", separator: "." },
        "CHF": { symbol: "CHF", precision: 2, delimiter: ".", separator: "," },
        "SGD": { symbol: "S$", precision: 2, delimiter: ",", separator: "." },
        "NZD": { symbol: "NZ$", precision: 2, delimiter: ",", separator: "." },
        "AUD": { symbol: "A$", precision: 2, delimiter: ",", separator: "." },
        "KRW": { symbol: "₩", precision: 0, delimiter: ",", separator: "." },
        "INR": { symbol: "₹", precision: 2, delimiter: ",", separator: "." }
    }

    def self.from_amount(amount, currency = "USD")
        Money.new(amount, currency)
    end

    def initialize(amount, currency = :USD)
        @amount = amount
        @currency = currency
    end

    def cents_part(precision: nil)
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
