default_currency_options = { unit: "$", precision: 2, delimiter: ",", separator: "." }

CURRENCY_OPTIONS = Hash.new { |hash, key| hash[key] = default_currency_options.dup }.merge(
  "USD": { unit: "$", precision: 2, delimiter: ",", separator: "." },
  "EUR": { unit: "€", precision: 2, delimiter: ".", separator: "," },
  "GBP": { unit: "£", precision: 2, delimiter: ",", separator: "." },
  "CAD": { unit: "C$", precision: 2, delimiter: ",", separator: "." },
  "MXN": { unit: "MX$", precision: 2, delimiter: ",", separator: "." },
  "HKD": { unit: "HK$", precision: 2, delimiter: ",", separator: "." },
  "CHF": { unit: "CHF", precision: 2, delimiter: ".", separator: "," },
  "SGD": { unit: "S$", precision: 2, delimiter: ",", separator: "." },
  "NZD": { unit: "NZ$", precision: 2, delimiter: ",", separator: "." },
  "AUD": { unit: "A$", precision: 2, delimiter: ",", separator: "." },
  "KRW": { unit: "₩", precision: 0, delimiter: ",", separator: "." },
  "INR": { unit: "₹", precision: 0, delimiter: ",", separator: "." }
)

EXCHANGE_RATE_ENABLED = ENV["OPEN_EXCHANGE_APP_ID"].present?
