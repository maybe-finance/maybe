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
        result[t.classification][category_id] ||= { amount: 0, subcategory: t.subcategory? }
        result[t.classification][category_id][:amount] += t.amount.abs
      end
    end

    # Calculate percentages for each group
    category_totals = []

    [ "income", "expense" ].each do |classification|
      totals = by_classification[classification]

      # Only include non-subcategory amounts in the total for percentage calculations
      total_amount = totals.sum do |_, data|
        data[:subcategory] ? 0 : data[:amount]
      end

      next if total_amount.zero?

      totals.each do |category_id, data|
        percentage = (data[:amount].to_f / total_amount * 100).round(1)

        category_totals << CategoryTotal.new(
          category_id: category_id,
          amount: data[:amount],
          percentage: percentage,
          classification: classification,
          currency: family.currency,
          subcategory?: data[:subcategory]
        )
      end
    end

    # Calculate totals based on non-subcategory amounts only
    total_income = category_totals
      .select { |ct| ct.classification == "income" && !ct.subcategory? }
      .sum(&:amount)

    total_expense = category_totals
      .select { |ct| ct.classification == "expense" && !ct.subcategory? }
      .sum(&:amount)

    CategoryTotals.new(
      total_income: total_income,
      total_expense: total_expense,
      category_totals: category_totals
    )
  end

  private
    Totals = Struct.new(:month, :year, :amount, :classification, :currency, :subcategory?, keyword_init: true)
    Stats = Struct.new(:avg, :median, :currency, keyword_init: true)
    CategoryTotals = Struct.new(:total_income, :total_expense, :category_totals, keyword_init: true)
    CategoryTotal = Struct.new(:category_id, :amount, :percentage, :classification, :currency, :subcategory?, keyword_init: true)

    def statistics_data
      @statistics_data ||= begin
        stats = totals_data.each_with_object({ nil => Stats.new(avg: 0, median: 0) }) do |(category_id, totals), hash|
          next if totals.empty?

          amounts = totals.map(&:amount)
          hash[category_id] = Stats.new(
            avg: (amounts.sum.to_f / amounts.size).round,
            median: calculate_median(amounts),
            currency: family.currency
          )
        end
      end
    end

    def totals_data
      @totals_data ||= begin
        totals = monthly_totals_query.each_with_object({ nil => [] }) do |row, hash|
          hash[row.category_id] ||= []
          existing_total = hash[row.category_id].find { |t| t.month == row.date.month && t.year == row.date.year }

          if existing_total
            existing_total.amount += row.total.to_i
          else
            hash[row.category_id] << Totals.new(
              month: row.date.month,
              year: row.date.year,
              amount: row.total.to_i,
              classification: row.classification,
              currency: family.currency,
              subcategory?: row.parent_category_id.present?
            )
          end

          # If category is a parent, its total includes its own transactions + sum(child category transactions)
          if row.parent_category_id
            hash[row.parent_category_id] ||= []

            existing_parent_total = hash[row.parent_category_id].find { |t| t.month == row.date.month && t.year == row.date.year }

            if existing_parent_total
              existing_parent_total.amount += row.total.to_i
            else
              hash[row.parent_category_id] << Totals.new(
                month: row.date.month,
                year: row.date.year,
                amount: row.total.to_i,
                classification: row.classification,
                currency: family.currency,
                subcategory?: false
              )
            end
          end
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
              "categories.parent_id as parent_category_id",
              income_expense_classification,
              "date_trunc('month', account_entries.date) as date",
              "SUM(account_entries.amount) as total"
            )
            .joins("LEFT JOIN categories ON categories.id = account_transactions.category_id")
            .group(Arel.sql("categories.id, categories.parent_id, #{income_expense_classification}, date_trunc('month', account_entries.date)"))
            .order(Arel.sql("date_trunc('month', account_entries.date) DESC"))
    end


    def calculate_median(numbers)
      return 0 if numbers.empty?

      sorted = numbers.sort
      mid = sorted.size / 2
      if sorted.size.odd?
        sorted[mid]
      else
        ((sorted[mid-1] + sorted[mid]) / 2.0).round
      end
    end
end
