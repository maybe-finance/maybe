class Account::Syncer
  def initialize(account, start_date: nil)
    @account = account
    @start_date = start_date
  end

  def run
    account.auto_match_transfers!

    holdings = sync_holdings
    balances = sync_balances(holdings)
    account.reload
    update_account_info(balances, holdings) unless account.plaid_account_id.present?
    convert_records_to_family_currency(balances, holdings) unless account.currency == account.family.currency

    # Enrich if user opted in or if we're syncing transactions from a Plaid account on the hosted app
    if account.family.data_enrichment_enabled? || (account.plaid_account_id.present? && Rails.application.config.app_mode.hosted?)
      account.enrich_data
    else
      Rails.logger.info("Data enrichment is disabled, skipping enrichment for account #{account.id}")
    end
  end

  private
    attr_reader :account, :start_date

    def account_start_date
      @account_start_date ||= (account.entries.chronological.first&.date || Date.current) - 1.day
    end

    def update_account_info(balances, holdings)
      new_balance = balances.sort_by(&:date).last.balance
      new_holdings_value = holdings.select { |h| h.date == Date.current }.sum(&:amount)
      new_cash_balance = new_balance - new_holdings_value

      account.update!(
        balance: new_balance,
        cash_balance: new_cash_balance
      )
    end

    def sync_holdings
      calculator = Account::HoldingCalculator.new(account)
      calculated_holdings = calculator.calculate(reverse: account.plaid_account_id.present?)

      current_time = Time.now

      Account.transaction do
        load_holdings(calculated_holdings)

        # Purge outdated holdings
        account.holdings.delete_by("date < ? OR security_id NOT IN (?)", account_start_date, calculated_holdings.map(&:security_id))
      end

      calculated_holdings
    end

    def sync_balances(holdings)
      calculator = Account::BalanceCalculator.new(account, holdings: holdings)
      calculated_balances = calculator.calculate(reverse: account.plaid_account_id.present?, start_date: start_date)

      Account.transaction do
        load_balances(calculated_balances)

        # Purge outdated balances
        account.balances.delete_by("date < ?", account_start_date)
      end

      calculated_balances
    end

    def convert_records_to_family_currency(balances, holdings)
      from_currency = account.currency
      to_currency = account.family.currency

      exchange_rates = ExchangeRate.find_rates(
        from: from_currency,
        to: to_currency,
        start_date: balances.min_by(&:date).date
      )

      converted_balances = balances.map do |balance|
        exchange_rate = exchange_rates.find { |er| er.date == balance.date }

        next unless exchange_rate.present?

        account.balances.build(
          date: balance.date,
          balance: exchange_rate.rate * balance.balance,
          currency: to_currency
        )
      end.compact

      converted_holdings = holdings.map do |holding|
        exchange_rate = exchange_rates.find { |er| er.date == holding.date }

        next unless exchange_rate.present?

        account.holdings.build(
          security: holding.security,
          date: holding.date,
          qty: holding.qty,
          price: exchange_rate.rate * holding.price,
          amount: exchange_rate.rate * holding.amount,
          currency: to_currency
        )
      end.compact

      Account.transaction do
        load_balances(converted_balances)
        load_holdings(converted_holdings)
      end
    end

    def load_balances(balances = [])
      current_time = Time.now
      account.balances.upsert_all(
        balances.map { |b| b.attributes
               .slice("date", "balance", "cash_balance", "currency")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id date currency]
      )
    end

    def load_holdings(holdings = [])
      current_time = Time.now
      account.holdings.upsert_all(
        holdings.map { |h| h.attributes
               .slice("date", "currency", "qty", "price", "amount", "security_id")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id security_id date currency]
      )
    end
end
