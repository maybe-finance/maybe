default_currency_options = { symbol: "$", precision: 2, delimiter: ",", separator: "." }

CURRENCY_OPTIONS = Hash.new { |hash, key| hash[key] = default_currency_options.dup }.merge(
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
)

EXCHANGE_RATE_ENABLED = ENV["OPEN_EXCHANGE_APP_ID"].present?
