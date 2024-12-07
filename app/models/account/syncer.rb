class Account::Syncer
  def initialize(account, start_date: nil)
    @account = account
    @start_date = start_date
  end

  def run
    sync_holdings
    account.reload
    sync_balances
    account.reload
    purge_stale_account_records

    account.reload

    update_account_info

    enrich_transactions
    enrich_holdings
  end

  private 
    attr_reader :account

    def update_account_info
      new_balance = account.balances.chronological.last.balance
      new_holdings_value = account.holdings.current.sum(:amount)
        new_cash_balance = new_balance - new_holdings_value

      account.update!(
        balance: new_balance,
        cash_balance: new_cash_balance
      )
    end

    def enrich_transactions
      # TODO: implement
    end

    def enrich_holdings
      # TODO: implement
    end

    def sync_holdings 
      holdings = Account::ReversePortfolioCalculator.new(account).calculate(reverse: account.plaid_account_id.present?)
      current_time = Time.now 
      account.holdings.upsert_all(
        holdings.map { |h| h.attributes
               .slice("date", "currency", "qty", "price", "amount", "security_id")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id security_id date currency]
      ) if holdings.any?
    end

    def sync_balances 
      balances = Account::ReverseBalanceCalculator.new(account).calculate(reverse: account.plaid_account_id.present?)
      load_balances(balances)
  
      # If account is in different currency than family, convert balances
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
        start_date: start_date
      )

      missing_exchange_rates = balances.map(&:date) - exchange_rates.map(&:date)

      if missing_exchange_rates.any?
        account.observe_missing_exchange_rates(from: from_currency, to: to_currency, dates: missing_exchange_rates)
        return []
      end

      balances.map do |balance|
        exchange_rate = exchange_rates.find { |er| er.date == balance.date }

        account.balances.build(
          date: balance.date,
          balance: exchange_rate.rate * balance.balance,
          currency: to_currency
        )
      end
    end

    def purge_stale_account_records
      cutoff_date = (account.entries.chronological.first&.date || Date.current) - 1.day
      account.holdings.delete_by("date < ?", cutoff_date)
      account.balances.delete_by("date < ?", cutoff_date)
    end
end
