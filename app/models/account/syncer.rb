class Account::Syncer
  def initialize(account, start_date: nil)
    @account = account
    @start_date = start_date
  end

  def run
    Rails.logger.tagged("Account::Syncer") do
      Rails.logger.info("Finding potential transfers to auto-match")
      account.family.auto_match_transfers!

      holdings = sync_holdings
      Rails.logger.info("Calculated #{holdings.size} holdings")

      balances = sync_balances(holdings)
      Rails.logger.info("Calculated #{balances.size} balances")

      account.reload

      unless plaid_sync?
        update_account_info(balances, holdings)
      end

      unless account.currency == account.family.currency
        Rails.logger.info("Converting #{balances.size} balances and #{holdings.size} holdings from #{account.currency} to #{account.family.currency}")
        convert_records_to_family_currency(balances, holdings)
      end

      # Enrich if user opted in or if we're syncing transactions from a Plaid account on the hosted app
      if account.family.data_enrichment_enabled? || (plaid_sync? && Rails.application.config.app_mode.hosted?)
        Rails.logger.info("Enriching transaction data for account #{account.name}")
        account.enrich_data
      else
        Rails.logger.info("Data enrichment disabled for account #{account.name}")
      end
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
      calculated_holdings = calculator.calculate(reverse: plaid_sync?)

      Account.transaction do
        load_holdings(calculated_holdings)
        purge_outdated_holdings if plaid_sync?
      end

      calculated_holdings
    end

    def sync_balances(holdings)
      calculator = Account::BalanceCalculator.new(account, holdings: holdings)
      calculated_balances = calculator.calculate(reverse: plaid_sync?, start_date: start_date)

      Account.transaction do
        load_balances(calculated_balances)
        purge_outdated_balances
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

    def purge_outdated_balances
      account.balances.delete_by("date < ?", account_start_date)
    end

    def plaid_sync?
      account.plaid_account_id.present?
    end

    def purge_outdated_holdings
      portfolio_security_ids = account.entries.account_trades.map { |entry| entry.entryable.security_id }.uniq

      # If there are no securities in the portfolio, delete all holdings
      if portfolio_security_ids.empty?
        account.holdings.delete_all
      else
        account.holdings.delete_by("date < ? OR security_id NOT IN (?)", account_start_date, portfolio_security_ids)
      end
    end
end
