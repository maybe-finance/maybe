class Assistant::Function::GetAccounts < Assistant::Function
  class << self
    def name
      "get_accounts"
    end

    def description
      "Use this to see what accounts the user has along with their current and historical balances"
    end
  end

  def call(params = {})
    account_type = params["account_type"] || "all"
    balance_sheet = BalanceSheet.new(family)

    {
      as_of_date: Date.today.to_s,
      currency: family.currency,
      accounts: get_accounts_data(balance_sheet, account_type)
    }
  end

  def params_schema
    {
      type: "object",
      properties: {
        account_type: {
          type: "string",
          enum: [ "asset", "liability", "all" ],
          description: "Type of accounts to get balances for"
        }
      },
      required: [ "account_type" ],
      additionalProperties: false
    }
  end

  private

    def get_accounts_data(balance_sheet, account_type)
      accounts = case account_type
      when "asset"
        balance_sheet.account_groups("asset")
      when "liability"
        balance_sheet.account_groups("liability")
      else
        balance_sheet.account_groups
      end

      accounts.flat_map { |group| format_accounts(group.accounts) }
    end

    def format_accounts(accounts)
      accounts.map do |account|
        {
          name: account.name,
          type: account.accountable_type,
          balance: format_currency(account.balance),
          classification: account.classification
        }
      end
    end

    def format_currency(amount)
      Money.new(amount, family.currency).format
    end
end
