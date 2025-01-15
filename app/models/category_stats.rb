class CategoryStats
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def avg_monthly_total_for(category)
    statistics_data[category.id]&.avg || 0
  end

  def median_monthly_total_for(category)
    statistics_data[category.id]&.median || 0
  end

  def month_total_for(category, date: Date.current)
    monthly_totals = totals_data[category.id]

    category_total = monthly_totals&.find { |mt| mt.month == date.month && mt.year == date.year }

    category_total&.amount || 0
  end

  def month_category_totals(date: Date.current)
    by_classification = Hash.new { |h, k| h[k] = {} }

    totals_data.each_with_object(by_classification) do |(category_id, totals), result|
      totals.each do |t|
        next unless t.month == date.month && t.year == date.year
        result[t.classification][category_id] ||= 0
        result[t.classification][category_id] += t.amount.abs
      end
    end

    income_totals = by_classification["income"]
    expense_totals = by_classification["expense"]

    # Calculate percentages for each group
    category_totals = []

    [ "income", "expense" ].each do |classification|
      totals = by_classification[classification]
      total_amount = totals.values.sum
      next if total_amount.zero?

      totals.each do |category_id, amount|
        category_totals << CategoryTotal.new(
          category_id: category_id,
          amount: amount,
          percentage: (amount.to_f / total_amount * 100).round(1),
          classification: classification,
          currency: family.currency
        )
      end
    end

    CategoryTotals.new(
      total_income: income_totals.values.sum,
      total_expense: expense_totals.values.sum,
      category_totals: category_totals
    )
  end

  # private
  Totals = Struct.new(:month, :year, :amount, :classification, :currency, keyword_init: true)
  Stats = Struct.new(:avg, :median, :currency, keyword_init: true)
  CategoryTotals = Struct.new(:total_income, :total_expense, :category_totals, keyword_init: true)
  CategoryTotal = Struct.new(:category_id, :amount, :percentage, :classification, :currency, keyword_init: true)

  def statistics_data
    @statistics_data ||= begin
      stats = Category
                .select(
                  "mtq.category_id as id",
                  "AVG(mtq.total) as avg",
                  "PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY mtq.total) as median"
                )
                .from(monthly_totals_query, :mtq)
                .group("mtq.category_id")

      stats.each_with_object({ nil => Stats.new(avg: 0, median: 0) }) do |row, hash|
        hash[row.id] = Stats.new(
          avg: row.avg.to_i,
          median: row.median.to_i,
          currency: family.currency
        )
      end
    end
  end

  def totals_data
    @totals_data ||= begin
      totals = monthly_totals_query.each_with_object({ nil => [] }) do |row, hash|
        hash[row.category_id] ||= []
        hash[row.category_id] << Totals.new(
          month: row.date.month,
          year: row.date.year,
          amount: row.total.to_i,
          classification: row.classification,
          currency: family.currency
        )
      end

      # Ensure we have a default empty array for nil category, which represents "Uncategorized"
      totals[nil] ||= []
      totals
    end
  end

  def monthly_totals_query
    income_expense_classification = Arel.sql("
      CASE WHEN categories.id IS NULL THEN
        CASE WHEN account_entries.amount < 0 THEN 'income' ELSE 'expense' END
      ELSE categories.classification
      END
    ")

    family.entries
          .incomes_and_expenses
          .select(
            "categories.id as category_id",
            income_expense_classification,
            "date_trunc('month', account_entries.date) as date",
            "SUM(account_entries.amount) as total"
          )
          .joins("LEFT JOIN categories ON categories.id = account_transactions.category_id")
          .group(Arel.sql("categories.id, #{income_expense_classification}, date_trunc('month', account_entries.date)"))
          .order(Arel.sql("date_trunc('month', account_entries.date) DESC"))
  end
end
