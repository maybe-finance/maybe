class Budget < ApplicationRecord
  include Monetizable

  belongs_to :family

  has_many :budget_categories, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validates :start_date, :end_date, uniqueness: { scope: :family_id }

  monetize :budgeted_amount, :expected_income, :allocated_amount

  class << self
    def min_year_for_family(family)
      family.oldest_entry_date.year
    end

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
        bc.budgeted_amount = 0
        bc.currency = family.currency
      end
    end

    # Uncategorized, "catch-all" bucket
    budget_categories.find_or_create_by(
      category: nil
    ) do |bc|
      bc.budgeted_amount = 0
      bc.currency = family.currency
    end
  end

  def name
    start_date.strftime("%B %Y")
  end

  def initialized?
    budgeted_amount.present?
  end

  def allocated?
    budget_categories.any?
  end

  def allocated_amount
    0
  end

  def unallocated_amount
    budgeted_amount_money - allocated_amount
  end

  def allocated_percent
    0
  end

  def utilization_percent
    (actual_amount / budgeted_amount_money) * 100
  end

  def over_budget?
    false
  end

  def actual_amount
    budget_categories.sum(&:actual_amount)
  end

  def actual_income
    Money.new(family.entries.incomes.where(date: start_date..end_date).sum(:amount).abs || 0, currency)
  end

  def actual_expenses
    Money.new(family.entries.expenses.where(date: start_date..end_date).sum(:amount).abs || 0, currency)
  end

  def remaining_income
    expected_income_money - actual_income
  end

  def income_progress_percent
    (actual_income / expected_income_money) * 100
  end

  def overage
    actual_amount - (budgeted_amount_money || Money.new(0, currency))
  end

  def unspent
    overage * -1
  end

  def exceeded_income?
    false
  end

  def total_spending
    Money.new(2000, currency)
  end

  def expected_income_estimate
    income = family.budgeting_stats.avg_monthly_income.abs

    return nil unless income.amount > 0

    income
  end

  def budgeted_amount_estimate
    expenses = family.budgeting_stats.avg_monthly_expenses
    return nil unless expenses.amount > 0

    expenses
  end

  def current?
    start_date == Date.today.beginning_of_month && end_date == Date.today.end_of_month
  end

  def previous_budget
    prev_month_start_date = start_date - 1.month
    return nil if prev_month_start_date < family.oldest_entry_date

    family.budgets.for_date(prev_month_start_date)
  end

  def next_budget
    return nil if current?

    next_start_date = start_date + 1.month

    family.budgets.for_date(next_start_date)
  end

  def to_donut_segments_json
    unused_segment_id = "unused"

    # Continuous gray segment for empty budgets
    return [ { color: "#F0F0F0", amount: 1, id: unused_segment_id } ] unless initialized?

    segments = budget_categories.map do |bc|
      { color: bc.category.color, amount: bc.actual_amount.amount, id: bc.id }
    end

    if unspent >= 0
      segments.push({ color: "#F0F0F0", amount: unspent.amount, id: unused_segment_id })
    end

    segments
  end
end
