class PlaidAccount::Liabilities::CreditProcessor
  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    return unless credit_data.present?

    account.credit_card.update!(
      minimum_payment: credit_data.dig("minimum_payment_amount"),
      apr: credit_data.dig("aprs", 0, "apr_percentage")
    )
  end

  private
    attr_reader :plaid_account

    def account
      plaid_account.account
    end

    def credit_data
      plaid_account.raw_liabilities_payload["credit"]
    end
end
