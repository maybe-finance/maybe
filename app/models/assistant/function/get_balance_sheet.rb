class Assistant::Function::GetBalanceSheet < Assistant::Function
  class << self
    def name
      "get_balance_sheet"
    end

    def description
      "Get current balance sheet information including net worth, assets, and liabilities"
    end
  end

  def call(params = {})
    balance_sheet = BalanceSheet.new(family)
    balance_sheet.to_ai_readable_hash
  end
end
