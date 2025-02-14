module Family::Aggregatable
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
  end

  def net_worth
    assets - liabilities
  end

  def assets
    Money.new(accounts.active.assets.map { |account| account.balance_money.exchange_to(currency, fallback_rate: 0) }.sum, currency)
  end

  def liabilities
    Money.new(accounts.active.liabilities.map { |account| account.balance_money.exchange_to(currency, fallback_rate: 0) }.sum, currency)
  end

  def net_worth_series(period = Period.last_30_days)
    start_date = period.date_range.first
    end_date = period.date_range.last

    total_days = (end_date - start_date).to_i
    date_interval = if total_days > 30 
      "7 days"
    else
      "1 day"
    end 

    query = <<~SQL
      WITH dates as (
        SELECT generate_series(DATE :start_date, DATE :end_date, :date_interval::interval)::date as date
      )
      SELECT
        d.date,
        COALESCE(SUM(ab.balance * COALESCE(er.rate, 1)), 0) as balance,
        COUNT(CASE WHEN a.currency <> :family_currency AND er.rate IS NULL THEN 1 END) as missing_rates
      FROM dates d
      LEFT JOIN accounts a ON (a.family_id = :family_id)
      LEFT JOIN account_balances ab ON (
        ab.date = d.date AND
        ab.currency = a.currency AND
        ab.account_id = a.id
      )
      LEFT JOIN exchange_rates er ON (
        er.date = ab.date AND
        er.from_currency = a.currency AND
        er.to_currency = :family_currency
      )
      GROUP BY d.date
      ORDER BY d.date
    SQL

    balances = Account::Balance.find_by_sql([
      query,
      family_id: self.id,
      family_currency: self.currency,
      start_date: start_date,
      end_date: end_date,
      date_interval: date_interval
    ])

    TimeSeries.from_collection(balances, :balance)
  end

  def snapshot(period = Period.all)
    query = accounts.active.joins(:balances)
              .where("account_balances.currency = ?", self.currency)
              .select(
                "account_balances.currency",
                "account_balances.date",
                "SUM(CASE WHEN accounts.classification = 'liability' THEN account_balances.balance ELSE 0 END) AS liabilities",
                "SUM(CASE WHEN accounts.classification = 'asset' THEN account_balances.balance ELSE 0 END) AS assets",
                "SUM(CASE WHEN accounts.classification = 'asset' THEN account_balances.balance WHEN accounts.classification = 'liability' THEN -account_balances.balance ELSE 0 END) AS net_worth",
              )
              .group("account_balances.date, account_balances.currency")
              .order("account_balances.date")

    query = query.where("account_balances.date >= ?", period.date_range.begin) if period.date_range.begin
    query = query.where("account_balances.date <= ?", period.date_range.end) if period.date_range.end
    result = query.to_a

    {
      asset_series: TimeSeries.new(result.map { |r| { date: r.date, value: Money.new(r.assets, r.currency) } }),
      liability_series: TimeSeries.new(result.map { |r| { date: r.date, value: Money.new(r.liabilities, r.currency) } }, favorable_direction: "down"),
      net_worth_series: TimeSeries.new(result.map { |r| { date: r.date, value: Money.new(r.net_worth, r.currency) } })
    }
  end

  def income_categories_with_totals(date: Date.current)
    categories_with_stats(classification: "income", date: date)
  end

  def expense_categories_with_totals(date: Date.current)
    categories_with_stats(classification: "expense", date: date)
  end

  def category_stats
    CategoryStats.new(self)
  end

  def budgeting_stats
    BudgetingStats.new(self)
  end

  def account_stats
    AccountStats.new(self)
  end

  private
    CategoriesWithTotals = Struct.new(:total_money, :category_totals, keyword_init: true)
    CategoryWithStats = Struct.new(:category, :amount_money, :percentage, keyword_init: true)

    def categories_with_stats(classification:, date: Date.current)
      totals = category_stats.month_category_totals(date: date)

      classified_totals = totals.category_totals.select { |t| t.classification == classification }

      if classification == "income"
        total = totals.total_income
        categories_scope = categories.incomes
      else
        total = totals.total_expense
        categories_scope = categories.expenses
      end

      categories_with_uncategorized = categories_scope + [ categories_scope.uncategorized ]

      CategoriesWithTotals.new(
        total_money: Money.new(total, currency),
        category_totals: categories_with_uncategorized.map do |category|
          ct = classified_totals.find { |ct| ct.category_id == category&.id }

          CategoryWithStats.new(
            category: category,
            amount_money: Money.new(ct&.amount || 0, currency),
            percentage: ct&.percentage || 0
          )
        end
      )
    end
end
