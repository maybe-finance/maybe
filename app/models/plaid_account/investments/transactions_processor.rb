class PlaidAccount::Investments::TransactionsProcessor
  def initialize(plaid_account, security_resolver:)
    @plaid_account = plaid_account
    @security_resolver = security_resolver
  end

  def process
    transactions.each do |transaction|
      resolved_security_result = security_resolver.resolve(plaid_security_id: transaction["security_id"])

      if resolved_security_result.security.present?
        find_or_create_trade_entry(transaction)
      else
        find_or_create_cash_entry(transaction)
      end
    end
  end

  private
    attr_reader :plaid_account, :security_resolver

    def account
      plaid_account.account
    end

    def find_or_create_trade_entry(transaction)
      entry = account.entries.find_or_initialize_by(plaid_id: transaction["investment_transaction_id"]) do |e|
        e.entryable = Trade.new
      end

      entry.enrich_attribute(
        :name,
        transaction["name"],
        source: "plaid"
      )

      entry.assign_attributes(
        amount: transaction["quantity"] * transaction["price"],
        currency: transaction["iso_currency_code"],
        date: transaction["date"]
      )

      entry.trade.assign_attributes(
        security: security,
        qty: transaction["quantity"],
        price: transaction["price"],
        currency: transaction["iso_currency_code"]
      )

      entry.save!
    end

    def find_or_create_cash_entry(transaction)
      entry = account.entries.find_or_initialize_by(plaid_id: transaction["investment_transaction_id"]) do |e|
        e.entryable = Transaction.new
      end

      entry.enrich_attribute(
        :name,
        transaction["name"],
        source: "plaid"
      )

      entry.assign_attributes(
        amount: transaction["amount"],
        currency: transaction["iso_currency_code"],
        date: transaction["date"]
      )

      entry.save!
    end

    def transactions
      plaid_account.raw_investments_payload["transactions"] || []
    end
end
