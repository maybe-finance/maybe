class CategoryStats
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def avg_monthly_total_for(category)
    avg = statistics_data[category.id]&.avg || 0

    Money.new(avg, family.currency)
  end

  def median_monthly_total_for(category)
    median = statistics_data[category.id]&.median || 0

    Money.new(median, family.currency)
  end

  def month_total_for(category, date: Date.current)
    monthly_totals = totals_data[category.id]

    category_total = monthly_totals&.find { |mt| mt.month == date.month && mt.year == date.year }

    Money.new(category_total&.amount || 0, family.currency)
  end

  # private
  Totals = Struct.new(:month, :year, :amount, keyword_init: true)
  Stats = Struct.new(:avg, :median, keyword_init: true)

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
          median: row.median.to_i
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
          amount: row.total.to_i
        )
      end

      # Ensure we have a default empty array for nil category, which represents "Uncategorized"
      totals[nil] ||= []
      totals
    end
  end

  def monthly_totals_query
    family.entries
          .incomes_and_expenses
          .select(
            "categories.id as category_id",
            "date_trunc('month', account_entries.date) as date",
            "SUM(account_entries.amount) as total"
          )
          .joins("LEFT JOIN categories ON categories.id = account_transactions.category_id")
          .group(Arel.sql("categories.id, date_trunc('month', account_entries.date)"))
          .order(Arel.sql("date_trunc('month', account_entries.date) DESC"))
  end
end
