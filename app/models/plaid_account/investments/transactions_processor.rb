class PlaidAccount::Investments::TransactionsProcessor
  SecurityNotFoundError = Class.new(StandardError)

  def initialize(plaid_account, security_resolver:)
    @plaid_account = plaid_account
    @security_resolver = security_resolver
  end

  def process
    transactions.each do |transaction|
      if cash_transaction?(transaction)
        find_or_create_cash_entry(transaction)
      else
        find_or_create_trade_entry(transaction)
      end
    end
  end

  private
    attr_reader :plaid_account, :security_resolver

    def account
      plaid_account.account
    end

    def cash_transaction?(transaction)
      transaction["type"] == "cash" || transaction["type"] == "fee"
    end

    def find_or_create_trade_entry(transaction)
      resolved_security_result = security_resolver.resolve(plaid_security_id: transaction["security_id"])

      unless resolved_security_result.security.present?
        Sentry.capture_exception(SecurityNotFoundError.new("Could not find security for plaid trade")) do |scope|
          scope.set_tags(plaid_account_id: plaid_account.id)
        end

        return # We can't process a non-cash transaction without a security
      end

      entry = account.entries.find_or_initialize_by(plaid_id: transaction["investment_transaction_id"]) do |e|
        e.entryable = Trade.new
      end

      entry.assign_attributes(
        amount: transaction["quantity"] * transaction["price"],
        currency: transaction["iso_currency_code"],
        date: transaction["date"]
      )

      entry.trade.assign_attributes(
        security: resolved_security_result.security,
        qty: transaction["quantity"],
        price: transaction["price"],
        currency: transaction["iso_currency_code"]
      )

      entry.enrich_attribute(
        :name,
        transaction["name"],
        source: "plaid"
      )

      entry.save!
    end

    def find_or_create_cash_entry(transaction)
      entry = account.entries.find_or_initialize_by(plaid_id: transaction["investment_transaction_id"]) do |e|
        e.entryable = Transaction.new
      end

      entry.assign_attributes(
        amount: transaction["amount"],
        currency: transaction["iso_currency_code"],
        date: transaction["date"]
      )

      entry.enrich_attribute(
        :name,
        transaction["name"],
        source: "plaid"
      )

      entry.save!
    end

    def transactions
      plaid_account.raw_investments_payload["transactions"] || []
    end
end
