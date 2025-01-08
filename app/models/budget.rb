class Budget < ApplicationRecord
  belongs_to :family

  has_many :budget_categories, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validates :start_date, :end_date, uniqueness: { scope: :family_id }

  class << self
    def current
      find_or_create_by(
        start_date: Date.today.beginning_of_month,
        end_date: Date.today.end_of_month
      )
    end

    def for_date(date)
      return nil if date > Date.current

      find_or_create_by(
        start_date: date.beginning_of_month,
        end_date: date.end_of_month
      )
    end

    def min_year_for_family(family)
      family.oldest_entry_date.year
    end
  end

  def name
    start_date.strftime("%B %Y")
  end

  def current?
    start_date == Date.today.beginning_of_month && end_date == Date.today.end_of_month
  end

  def previous_budget
    prev_start_date = start_date - 1.month
    prev_end_date = prev_start_date.end_of_month

    return nil if prev_end_date < family.oldest_entry_date

    family.budgets.find_or_create_by(start_date: prev_start_date, end_date: prev_end_date)
  end

  def next_budget
    return nil if current?

    next_start_date = start_date + 1.month
    next_end_date = next_start_date.end_of_month

    family.budgets.find_or_create_by(start_date: next_start_date, end_date: next_end_date)
  end
end
