class Budget < ApplicationRecord
  include Monetizable

  belongs_to :family

  has_many :budget_categories, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validates :start_date, :end_date, uniqueness: { scope: :family_id }

  monetize :budgeted_spending, :expected_income, :allocated_spending,
           :actual_spending, :available_to_spend, :available_to_allocate,
           :estimated_spending, :estimated_income, :actual_income, :remaining_expected_income

  class << self
    def for_date(date)
      find_by(start_date: date.beginning_of_month, end_date: date.end_of_month)
    end

    def find_or_bootstrap(family, date: Date.current)
      Budget.transaction do
        budget = Budget.find_or_create_by!(
          family: family,
          start_date: date.beginning_of_month,
          end_date: date.end_of_month
        ) do |b|
          b.currency = family.currency
        end

        budget.sync_budget_categories

        budget
      end
    end
  end

  def period
    Period.new(start_date: start_date, end_date: end_date)
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
    budget_categories.uncategorized.tap do |bc|
      bc.budgeted_spending = [ available_to_allocate, 0 ].max
      bc.currency = family.currency
    end
  end

  def transactions
    family.transactions.active.in_period(period)
  end

  def name
    start_date.strftime("%B %Y")
  end

  def initialized?
    budgeted_spending.present?
  end

  def income_category_totals
    family.income_statement.income(period: period).category_totals.reject { |ct| ct.category.subcategory? }.sort_by(&:weight).reverse
  end

  def expense_category_totals
    family.income_statement.expense(period: period).category_totals.reject { |ct| ct.category.subcategory? }.sort_by(&:weight).reverse
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

  def to_donut_segments_json
    unused_segment_id = "unused"

    # Continuous gray segment for empty budgets
    return [ { color: "#F0F0F0", amount: 1, id: unused_segment_id } ] unless allocations_valid?

    segments = budget_categories.includes(:category).map do |bc|
      { color: bc.category.color, amount: bc.actual_spending, id: bc.id }
    end

    if available_to_spend.positive?
      segments.push({ color: "#F0F0F0", amount: available_to_spend, id: unused_segment_id })
    end

    segments
  end

  # =============================================================================
  # Actuals: How much user has spent on each budget category
  # =============================================================================
  def estimated_spending
    family.income_statement.median_expense(interval: "month")
  end

  def actual_spending
    family.income_statement.expense(period: self.period).total
  end

  def available_to_spend
    (budgeted_spending || 0) - actual_spending
  end

  def percent_of_budget_spent
    return 0 unless budgeted_spending > 0

    (actual_spending / budgeted_spending.to_f) * 100
  end

  def overage_percent
    return 0 unless available_to_spend.negative?

    available_to_spend.abs / actual_spending.to_f * 100
  end

  # =============================================================================
  # Budget allocations: How much user has budgeted for all parent categories combined
  # =============================================================================
  def allocated_spending
    budget_categories.reject { |bc| bc.subcategory? }.sum(&:budgeted_spending)
  end

  def allocated_percent
    return 0 unless budgeted_spending && budgeted_spending > 0

    (allocated_spending / budgeted_spending.to_f) * 100
  end

  def available_to_allocate
    (budgeted_spending || 0) - allocated_spending
  end

  def allocations_valid?
    initialized? && available_to_allocate >= 0 && allocated_spending > 0
  end

  # =============================================================================
  # Income: How much user earned relative to what they expected to earn
  # =============================================================================
  def estimated_income
    family.income_statement.median_income(interval: "month")
  end

  def actual_income
    family.income_statement.income(period: self.period).total
  end

  def actual_income_percent
    return 0 unless expected_income > 0

    (actual_income / expected_income.to_f) * 100
  end

  def remaining_expected_income
    expected_income - actual_income
  end

  def surplus_percent
    return 0 unless remaining_expected_income.negative?

    remaining_expected_income.abs / expected_income.to_f * 100
  end
end
