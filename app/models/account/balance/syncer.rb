class Account::Balance::Syncer
  attr_reader :account, :strategy

  def initialize(account, strategy:)
    @account = account
    @strategy = strategy
  end

  def sync_balances
    Rails.logger.tagged("Account::Balance::Syncer") do
      Account::Balance.transaction do
        sync_holdings
        calculate_balances
        persist_balances
        purge_stale_balances
        update_account_info unless strategy == :reverse
      end
    end
  end

  private
    def sync_holdings
      @holdings = Account::Holding::Syncer.new(account, strategy: strategy).sync_holdings
    end

    def update_account_info
      calculated_balance = @balances.sort_by(&:date).last&.balance || 0
      calculated_holdings_value = @holdings.select { |h| h.date == Date.current }.sum(&:amount) || 0
      calculated_cash_balance = calculated_balance - calculated_holdings_value

      Rails.logger.info("Updating account balances: cash=#{calculated_cash_balance}, total=#{calculated_balance}")

      account.update!(
        balance: calculated_balance,
        cash_balance: calculated_cash_balance
      )
    end

    def calculate_balances
      @balances = calculator.calculate
    end

    def persist_balances
      current_time = Time.now

      Rails.logger.info("Upserting #{@balances.size} balances")

      account.balances.upsert_all(
        @balances.map { |b| b.attributes
               .slice("date", "balance", "cash_balance", "currency")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id date currency]
      )
    end

    def purge_stale_balances
      deleted_count = account.balances.delete_by("date < ?", account.start_date)
      Rails.logger.info("Deleted #{deleted_count} stale balances") if deleted_count > 0
    end

    def calculator
      if strategy == :reverse
        Account::Balance::ReverseCalculator.new(account)
      else
        Account::Balance::ForwardCalculator.new(account)
      end
    end
end
