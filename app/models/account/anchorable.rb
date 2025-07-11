# All accounts are "anchored" with start/end valuation records, with transactions,
# trades, and reconciliations between them.
module Account::Anchorable
  extend ActiveSupport::Concern

  included do
    include Monetizable

    monetize :opening_balance, :opening_cash_balance
  end

  def set_opening_balance(**opts)
    opening_balance_manager.set_opening_balance(**opts)
  end

  def opening_date
    opening_balance_manager.opening_date
  end

  def opening_balance
    opening_balance_manager.opening_balance
  end

  def opening_cash_balance
    opening_balance_manager.opening_cash_balance
  end

  private
    def opening_balance_manager
      @opening_balance_manager ||= Account::OpeningBalanceManager.new(self)
    end
end
