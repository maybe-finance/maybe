class Budget < ApplicationRecord
  include Monetizable

  belongs_to :family

  has_many :budget_categories, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validates :start_date, :end_date, uniqueness: { scope: :family_id }

  monetize :budgeted_spending, :expected_income, :allocated_spending,
           :actual_spending, :unallocated_spending, :vs_allocated, :vs_actual,
           :vs_expected_income, :estimated_spending, :estimated_income, :actual_income

  class << self
    def for_date(date)
      find_by(start_date: date.beginning_of_month, end_date: date.end_of_month)
    end

    def find_or_bootstrap(family, date: Date.current)
      Budget.transaction do
        budget = Budget.find_or_create_by(
          family: family,
          start_date: date.beginning_of_month,
          end_date: date.end_of_month,
          currency: family.currency
        )

        budget.sync_budget_categories

        budget
      end
    end
  end

  def sync_budget_categories
    family.categories.expenses.each do |category|
      budget_categories.find_or_create_by(
        category: category,
      ) do |bc|
        bc.budgeted_spending = 0
        bc.currency = family.currency
      end
    end
  end

  def uncategorized_budget_category
    budget_categories.build(
      category: nil,
      budgeted_spending: [ unallocated_spending, 0 ].max,
      currency: family.currency
    )
  end

  def name
    start_date.strftime("%B %Y")
  end

  def initialized?
    budgeted_spending.present?
  end

  def allocations_valid?
    initialized? && !over_allocated? && allocated_spending > 0
  end

  def estimated_spending
    family.budgeting_stats.avg_monthly_expenses
  end

  def actual_spending
    budget_categories.sum(&:actual_spending)
  end

  def allocated_spending
    budget_categories.sum(:budgeted_spending)
  end

  def unallocated_spending
    (budgeted_spending || 0) - allocated_spending
  end

  def vs_allocated
    allocated_spending - budgeted_spending
  end

  def vs_allocated_percent
    return 0 unless budgeted_spending > 0

    (allocated_spending / budgeted_spending) * 100
  end

  def over_allocated?
    budgeted_spending.present? && allocated_spending > budgeted_spending
  end

  def over_budget?
    vs_actual.positive?
  end

  def within_budget?
    vs_actual.negative? || vs_actual.zero?
  end

  def vs_actual
    actual_spending - (budgeted_spending || 0)
  end

  def vs_actual_percent
    return 0 unless budgeted_spending > 0

    (actual_spending / budgeted_spending) * 100
  end

  def estimated_income
    family.budgeting_stats.avg_monthly_income.abs
  end

  def actual_income
    family.entries.incomes.where(date: start_date..end_date).sum(:amount).abs
  end

  def vs_expected_income
    actual_income - expected_income
  end

  def vs_expected_income_percent
    return 0 unless expected_income > 0

    (actual_income / expected_income) * 100
  end

  def current?
    start_date == Date.today.beginning_of_month && end_date == Date.today.end_of_month
  end

  def previous_budget
    prev_month_end_date = end_date - 1.month
    return nil if prev_month_end_date < family.oldest_entry_date

    family.budgets.find_or_bootstrap(family, date: prev_month_end_date)
  end

  def next_budget
    return nil if current?

    next_start_date = start_date + 1.month

    family.budgets.find_or_bootstrap(family, date: next_start_date)
  end

  def income_categories_with_totals
    family.income_categories_with_totals(date: start_date)
  end

  def expense_categories_with_totals
    family.expense_categories_with_totals(date: start_date)
  end

  def to_donut_segments_json
    unused_segment_id = "unused"

    # Continuous gray segment for empty budgets
    return [ { color: "#F0F0F0", amount: 1, id: unused_segment_id } ] unless allocations_valid?

    segments = budget_categories.map do |bc|
      { color: bc.category.color, amount: bc.actual_spending, id: bc.id }
    end

    if within_budget?
      segments.push({ color: "#F0F0F0", amount: vs_actual * -1, id: unused_segment_id })
    end

    segments
  end
end
