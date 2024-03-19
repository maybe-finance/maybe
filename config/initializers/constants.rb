EXCHANGE_RATE_ENABLED = ENV["OPEN_EXCHANGE_APP_ID"].present?

BALANCE_SHEET_CLASSIFICATIONS = {
  asset: "asset",
  liability: "liability",
  equity: "equity"
}.freeze
