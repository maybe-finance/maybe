class PlaidAccount::Investments::HoldingsProcessor
  def initialize(plaid_account, security_resolver:)
    @plaid_account = plaid_account
    @security_resolver = security_resolver
  end

  def process
    holdings.each do |plaid_holding|
      resolved_security_result = security_resolver.resolve(plaid_security_id: plaid_holding["security_id"])

      next unless resolved_security_result.security.present?

      security = resolved_security_result.security
      holding_date = plaid_holding["institution_price_as_of"] || Date.current

      holding = account.holdings.find_or_initialize_by(
        security: security,
        date: holding_date,
        currency: plaid_holding["iso_currency_code"]
      )

      holding.assign_attributes(
        qty: plaid_holding["quantity"],
        price: plaid_holding["institution_price"],
        amount: plaid_holding["quantity"] * plaid_holding["institution_price"]
      )

      ActiveRecord::Base.transaction do
        holding.save!

        # Delete all holdings for this security after the institution price date
        account.holdings
          .where(security: security)
          .where("date > ?", holding_date)
          .destroy_all
      end
    end
  end

  private
    attr_reader :plaid_account, :security_resolver

    def account
      plaid_account.account
    end

    def holdings
      plaid_account.raw_investments_payload["holdings"] || []
    end
end
