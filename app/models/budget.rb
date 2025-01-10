class Budget < ApplicationRecord
  include Monetizable

  belongs_to :family

  has_many :budget_categories, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validates :start_date, :end_date, uniqueness: { scope: :family_id }

  monetize :budgeted_amount, :expected_income

  class << self
    def current(currency)
      find_or_create_by(
        start_date: Date.today.beginning_of_month,
        end_date: Date.today.end_of_month,
        currency: currency
      )
    end

    def for_date(date, currency)
      return nil if date > Date.current

      find_or_create_by(
        start_date: date.beginning_of_month,
        end_date: date.end_of_month,
        currency: currency
      )
    end

    def min_year_for_family(family)
      family.oldest_entry_date.year
    end
  end

  def initialize_budget_categories
    family.categories.each do |category|
      budget_categories.find_or_create_by(category: category, budgeted_amount: 0)
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
    Money.new(0, currency)
  end

  def unallocated_amount
    budgeted_amount_money - allocated_amount
  end

  def allocated_percent
    0
  end

  def over_budget?
    false
  end

  def exceeded_income?
    false
  end

  def total_spending
    Money.new(2000, currency)
  end

  # For now, just grab the value from the previous month (in future, we'll enhance this with longer-term averages)
  def expected_income_estimate
    income = family.entries.income_total(currency,
                                       start_date: prev_month_date_range.first,
                                       end_date: prev_month_date_range.last).abs

    return nil unless income.amount > 0

    income
  end

  # For now, just grab the value from the previous month (in future, we'll enhance this with longer-term averages)
  def budgeted_amount_estimate
    expenses = family.entries.expense_total(currency,
                                          start_date: prev_month_date_range.first,
                                          end_date: prev_month_date_range.last).abs

    return nil unless expenses.amount > 0

    expenses
  end

  def current?
    start_date == Date.today.beginning_of_month && end_date == Date.today.end_of_month
  end

  def previous_budget(currency)
    return nil if prev_month_date_range.first < family.oldest_entry_date

    family.budgets.find_or_create_by(start_date: prev_month_date_range.first, end_date: prev_month_date_range.last, currency: currency)
  end

  def next_budget(currency)
    return nil if current?

    next_start_date = start_date + 1.month
    next_end_date = next_start_date.end_of_month

    family.budgets.find_or_create_by(start_date: next_start_date, end_date: next_end_date, currency: currency)
  end

  private
    def prev_month_date_range
      prev_month_start_date = start_date - 1.month
      prev_month_end_date = prev_month_start_date.end_of_month

      prev_month_start_date..prev_month_end_date
    end
end
