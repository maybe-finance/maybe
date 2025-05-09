class PlaidInvestmentSync
  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def sync!(transactions: [], holdings: [], securities: [])
    @transactions = transactions
    @holdings = holdings
    @securities = securities

    PlaidAccount.transaction do
      normalize_cash_balance!
      sync_transactions!
      sync_holdings!
    end
  end

  private
    attr_reader :transactions, :holdings, :securities

    # Plaid considers "brokerage cash" and "cash equivalent holdings" to all be part of "cash balance"
    # Internally, we DO NOT.
    # Maybe clearly distinguishes between "brokerage cash" vs. "holdings (i.e. invested cash)"
    # For this reason, we must back out cash + cash equivalent holdings from the reported cash balance to avoid double counting
    def normalize_cash_balance!
      excludable_cash_holdings = holdings.select do |h|
        internal_security, plaid_security = get_security(h.security_id, securities)
        internal_security.present? && (plaid_security&.is_cash_equivalent || plaid_security&.type == "cash")
      end

      excludable_cash_holdings_value = excludable_cash_holdings.sum { |h| h.quantity * h.institution_price }

      plaid_account.account.update!(
        cash_balance: plaid_account.account.cash_balance - excludable_cash_holdings_value
      )
    end

    def sync_transactions!
      transactions.each do |transaction|
        security, plaid_security = get_security(transaction.security_id, securities)

        next if security.nil? && plaid_security.nil?

        if transaction.type == "cash" || plaid_security.ticker_symbol == "CUR:USD"
          new_transaction = plaid_account.account.entries.find_or_create_by!(plaid_id: transaction.investment_transaction_id) do |t|
            t.name = transaction.name
            t.amount = transaction.amount
            t.currency = transaction.iso_currency_code
            t.date = transaction.date
            t.entryable = Transaction.new
          end
        else
          new_transaction = plaid_account.account.entries.find_or_create_by!(plaid_id: transaction.investment_transaction_id) do |t|
            t.name = transaction.name
            t.amount = transaction.quantity * transaction.price
            t.currency = transaction.iso_currency_code
            t.date = transaction.date
            t.entryable = Trade.new(
              security: security,
              qty: transaction.quantity,
              price: transaction.price,
              currency: transaction.iso_currency_code
            )
          end
        end
      end
    end

    def sync_holdings!
      # Update only the current day holdings.  The account sync will populate historical values based on trades.
      holdings.each do |holding|
        internal_security, _plaid_security = get_security(holding.security_id, securities)

        next if internal_security.nil?

        existing_holding = plaid_account.account.holdings.find_or_initialize_by(
          security: internal_security,
          date: Date.current,
          currency: holding.iso_currency_code
        )

        existing_holding.qty = holding.quantity
        existing_holding.price = holding.institution_price
        existing_holding.amount = holding.quantity * holding.institution_price
        existing_holding.save!
      end
    end

    def get_security(plaid_security_id, securities)
      plaid_security = securities.find { |s| s.security_id == plaid_security_id }

      return [ nil, nil ] if plaid_security.nil?

      plaid_security = if plaid_security.ticker_symbol.present?
        plaid_security
      else
        securities.find { |s| s.security_id == plaid_security.proxy_security_id }
      end

      return [ nil, nil ] if plaid_security.nil? || plaid_security.ticker_symbol.blank?
      return [ nil, plaid_security ] if plaid_security.ticker_symbol == "CUR:USD" # internally, we do not consider cash a security and track it separately

      operating_mic = plaid_security.market_identifier_code

      # Find any matching security
      security = Security.find_or_create_by!(
        ticker: plaid_security.ticker_symbol&.upcase,
        exchange_operating_mic: operating_mic&.upcase
      )

      [ security, plaid_security ]
    end
end
