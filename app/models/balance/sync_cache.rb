class Balance::SyncCache
  def initialize(account)
    @account = account
  end

  def get_reconciliation_valuation(date)
    converted_entries.find { |e| e.date == date && e.valuation? && e.valuation.reconciliation? }
  end

  def get_holdings(date)
    converted_holdings.select { |h| h.date == date }
  end

  def get_entries(date)
    converted_entries.select { |e| e.date == date && (e.transaction? || e.trade?) }
  end

  private
    attr_reader :account

    def converted_entries
      @converted_entries ||= account.entries.order(:date).to_a.map do |e|
        converted_entry = e.dup
        converted_entry.amount = converted_entry.amount_money.exchange_to(
          account.currency,
          date: e.date,
          fallback_rate: 1
        ).amount
        converted_entry.currency = account.currency
        converted_entry
      end
    end

    def converted_holdings
      @converted_holdings ||= account.holdings.map do |h|
        converted_holding = h.dup
        converted_holding.amount = converted_holding.amount_money.exchange_to(
          account.currency,
          date: h.date,
          fallback_rate: 1
        ).amount
        converted_holding.currency = account.currency
        converted_holding
      end
    end
end
