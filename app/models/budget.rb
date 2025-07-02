class Budget < ApplicationRecord
  include Monetizable

  PARAM_DATE_FORMAT = "%b-%Y"

  belongs_to :family

  has_many :budget_categories, -> { includes(:category) }, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validates :start_date, :end_date, uniqueness: { scope: :family_id }

  monetize :budgeted_spending, :expected_income, :allocated_spending,
           :actual_spending, :available_to_spend, :available_to_allocate,
           :estimated_spending, :estimated_income, :actual_income, :remaining_expected_income

  class << self
    def date_to_param(date)
      date.strftime(PARAM_DATE_FORMAT).downcase
    end

    def param_to_date(param)
      Date.strptime(param, PARAM_DATE_FORMAT).beginning_of_month
    end

    def budget_date_valid?(date, family:)
      beginning_of_month = date.beginning_of_month

      beginning_of_month >= oldest_valid_budget_date(family) && beginning_of_month <= Date.current.end_of_month
    end

    def find_or_bootstrap(family, start_date:)
      return nil unless budget_date_valid?(start_date, family: family)

      Budget.transaction do
        budget = Budget.find_or_create_by!(
          family: family,
          start_date: start_date.beginning_of_month,
          end_date: start_date.end_of_month
        ) do |b|
          b.currency = family.currency
        end

        budget.sync_budget_categories

        budget
      end
    end

    private
      def oldest_valid_budget_date(family)
        @oldest_valid_budget_date ||= family.oldest_entry_date.beginning_of_month
      end
  end

  def period
    Period.custom(start_date: start_date, end_date: end_date)
  end

  def to_param
    self.class.date_to_param(start_date)
  end

  def sync_budget_categories
    current_category_ids = family.categories.expenses.pluck(:id).to_set
    existing_budget_category_ids = budget_categories.pluck(:category_id).to_set
    categories_to_add = current_category_ids - existing_budget_category_ids
    categories_to_remove = existing_budget_category_ids - current_category_ids

    # Create missing categories
    categories_to_add.each do |category_id|
      budget_categories.create!(
        category_id: category_id,
        budgeted_spending: 0,
        currency: family.currency
      )
    end

    # Remove old categories
    budget_categories.where(category_id: categories_to_remove).destroy_all if categories_to_remove.any?
  end

  def uncategorized_budget_category
    budget_categories.uncategorized.tap do |bc|
      bc.budgeted_spending = [ available_to_allocate, 0 ].max
      bc.currency = family.currency
    end
  end

  def transactions
    family.transactions.visible.in_period(period)
  end

  def name
    start_date.strftime("%B %Y")
  end

  def initialized?
    budgeted_spending.present?
  end

  def income_category_totals
    income_totals.category_totals.reject { |ct| ct.category.subcategory? || ct.total.zero? }.sort_by(&:weight).reverse
  end

  def expense_category_totals
    expense_totals.category_totals.reject { |ct| ct.category.subcategory? || ct.total.zero? }.sort_by(&:weight).reverse
  end

  def current?
    start_date == Date.today.beginning_of_month && end_date == Date.today.end_of_month
  end

  def previous_budget_param
    previous_date = start_date - 1.month
    return nil unless self.class.budget_date_valid?(previous_date, family: family)

    self.class.date_to_param(previous_date)
  end

  def next_budget_param
    return nil if current?

    next_date = start_date + 1.month
    return nil unless self.class.budget_date_valid?(next_date, family: family)

    self.class.date_to_param(next_date)
  end

  def to_donut_segments_json
    unused_segment_id = "unused"

    # Continuous gray segment for empty budgets
    return [ { color: "var(--budget-unallocated-fill)", amount: 1, id: unused_segment_id } ] unless allocations_valid?

    segments = budget_categories.map do |bc|
      { color: bc.category.color, amount: budget_category_actual_spending(bc), id: bc.id }
    end

    if available_to_spend.positive?
      segments.push({ color: "var(--budget-unallocated-fill)", amount: available_to_spend, id: unused_segment_id })
    end

    segments
  end

  # =============================================================================
  # Actuals: How much user has spent on each budget category
  # =============================================================================
  def estimated_spending
    income_statement.median_expense(interval: "month")
  end

  def actual_spending
    expense_totals.total
  end

  def budget_category_actual_spending(budget_category)
    expense_totals.category_totals.find { |ct| ct.category.id == budget_category.category.id }&.total || 0
  end

  def category_median_monthly_expense(category)
    income_statement.median_expense(category: category)
  end

  def category_avg_monthly_expense(category)
    income_statement.avg_expense(category: category)
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
    family.income_statement.income_totals(period: self.period).total
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

  private
    def income_statement
      @income_statement ||= family.income_statement
    end

    def expense_totals
      @expense_totals ||= income_statement.expense_totals(period: period)
    end

    def income_totals
      @income_totals ||= family.income_statement.income_totals(period: period)
    end
end
