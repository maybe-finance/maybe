class PlaidAccount::LiabilitiesProcessor
  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    if account.credit_card? && credit_data.present?
      account.credit_card.update!(
        minimum_payment: credit_data.dig("minimum_payment_amount"),
        apr: credit_data.dig("aprs", 0, "apr_percentage")
      )
    end

    if account.loan? && mortgage_data.present?
      account.loan.update!(
        rate_type: mortgage_data.dig("interest_rate", "type"),
        interest_rate: mortgage_data.dig("interest_rate", "percentage")
      )
    end

    if account.loan? && student_loan_data.present?
      term_months = if student_loan_data["origination_date"] && student_loan_data["expected_payoff_date"]
        (student_loan_data["expected_payoff_date"] - student_loan_data["origination_date"]).to_i / 30
      else
        nil
      end

      account.loan.update!(
        rate_type: "fixed",
        interest_rate: student_loan_data["interest_rate_percentage"],
        initial_balance: student_loan_data["origination_principal_amount"],
        term_months: term_months
      )
    end
  end

  private
    def account
      plaid_account.account
    end

    def credit_data
      plaid_account.raw_liabilities_payload["credit"]
    end

    def mortgage_data
      plaid_account.raw_liabilities_payload["mortgage"]
    end

    def student_loan_data
      plaid_account.raw_liabilities_payload["student"]
    end
end
