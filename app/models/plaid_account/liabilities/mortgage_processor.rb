class PlaidAccount::Liabilities::MortgageProcessor
  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    return unless mortgage_data.present?

    account.loan.update!(
      rate_type: mortgage_data.dig("interest_rate", "type"),
      interest_rate: mortgage_data.dig("interest_rate", "percentage")
    )
  end

  private
    attr_reader :plaid_account

    def account
      plaid_account.account
    end

    def mortgage_data
      plaid_account.raw_liabilities_payload["mortgage"]
    end
end
