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
      transaction["type"] == "cash" || transaction["type"] == "fee" || transaction["type"] == "transfer"
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
        amount: derived_qty(transaction) * transaction["price"],
        currency: transaction["iso_currency_code"],
        date: transaction["date"]
      )

      entry.trade.assign_attributes(
        security: resolved_security_result.security,
        qty: derived_qty(transaction),
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

    # Plaid unfortunately returns incorrect signage on some `quantity` values. They claim all "sell" transactions
    # are negative signage, but we have found multiple instances of production data where this is not the case.
    #
    # This method attempts to use several Plaid data points to derive the true quantity with the correct signage.
    def derived_qty(transaction)
      reported_qty = transaction["quantity"]
      abs_qty = reported_qty.abs

      if transaction["type"] == "sell" || transaction["amount"] < 0
        -abs_qty
      elsif transaction["type"] == "buy" || transaction["amount"] > 0
        abs_qty
      else
        reported_qty
      end
    end
end
