class PlaidAccount::InvestmentsProcessor
  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    puts "processing investments!"
    transactions.each do |transaction|
      process_investment_transaction(transaction)
    end

    holdings.each do |holding|
      process_holding(holding)
    end
  end

  private
    def account
      plaid_account.account
    end

    def process_investment_transaction(transaction)
      security, plaid_security = get_security(transaction["security_id"])

      return if security.nil?

      if transaction["type"] == "cash" || plaid_security["ticker_symbol"] == "CUR:USD"
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
      else
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
    end

    def process_holding(plaid_holding)
      internal_security, _plaid_security = get_security(plaid_holding["security_id"])

      return if internal_security.nil?

      holding = account.holdings.find_or_initialize_by(
        security: internal_security,
        date: Date.current,
        currency: plaid_holding["iso_currency_code"]
      )

      holding.assign_attributes(
        qty: plaid_holding["quantity"],
        price: plaid_holding["institution_price"],
        amount: plaid_holding["quantity"] * plaid_holding["institution_price"]
      )

      holding.save!
    end

    def transactions
      plaid_account.raw_investments_payload["transactions"] || []
    end

    def holdings
      plaid_account.raw_investments_payload["holdings"] || []
    end

    def securities
      plaid_account.raw_investments_payload["securities"] || []
    end

    def get_security(plaid_security_id)
      plaid_security = securities.find { |s| s["security_id"] == plaid_security_id }

      return [ nil, nil ] if plaid_security.nil?

      plaid_security = if plaid_security["ticker_symbol"].present?
        plaid_security
      else
        securities.find { |s| s["security_id"] == plaid_security["proxy_security_id"] }
      end

      return [ nil, nil ] if plaid_security.nil? || plaid_security["ticker_symbol"].blank?
      return [ nil, plaid_security ] if plaid_security["ticker_symbol"] == "CUR:USD" # internally, we do not consider cash a security and track it separately

      operating_mic = plaid_security["market_identifier_code"]

      # Find any matching security
      security = Security.find_or_create_by!(
        ticker: plaid_security["ticker_symbol"]&.upcase,
        exchange_operating_mic: operating_mic&.upcase
      )

      [ security, plaid_security ]
    end
end
