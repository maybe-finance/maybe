class Account::Syncer
  def initialize(account, start_date: nil)
    @account = account
    @start_date = start_date
  end

  def run
    holdings = sync_holdings
    balances = sync_balances(holdings)
    update_account_info(balances, holdings)
    convert_foreign_records(balances)
    purge_stale_account_records
  end

  private
    attr_reader :account, :start_date

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
      account.holdings.upsert_all(
        calculated_holdings.map { |h| h.attributes
               .slice("date", "currency", "qty", "price", "amount", "security_id")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id security_id date currency]
      ) if calculated_holdings.any?

      calculated_holdings
    end

    def sync_balances(holdings)
      calculator = Account::BalanceCalculator.new(account, holdings: holdings)
      calculated_balances = calculator.calculate(reverse: account.plaid_account_id.present?, start_date: start_date)

      load_balances(calculated_balances)

      calculated_balances
    end

    def convert_foreign_records(balances)
      converted_balances = convert_balances(balances)
      load_balances(converted_balances)
    end

    def load_balances(balances)
      current_time = Time.now
      account.balances.upsert_all(
        balances.map { |b| b.attributes
               .slice("date", "balance", "cash_balance", "currency")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id date currency]
      ) if balances.any?
    end

    def convert_balances(balances)
      return [] if account.currency == account.family.currency

      from_currency = account.currency
      to_currency = account.family.currency

      exchange_rates = ExchangeRate.find_rates(
        from: from_currency,
        to: to_currency,
        start_date: balances.first.date
      )

      balances.map do |balance|
        exchange_rate = exchange_rates.find { |er| er.date == balance.date }

        account.balances.build(
          date: balance.date,
          balance: exchange_rate.rate * balance.balance,
          currency: to_currency
        ) if exchange_rate.present?
      end
    end

    def purge_stale_account_records
      cutoff_date = (account.entries.chronological.first&.date || Date.current) - 1.day
      Account.transaction do
        account.holdings.delete_by("date < ?", cutoff_date)
        account.balances.delete_by("date < ?", cutoff_date)
      end
    end
end
