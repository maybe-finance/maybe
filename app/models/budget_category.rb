class BudgetCategory < ApplicationRecord
  include Monetizable

  belongs_to :budget
  belongs_to :category

  validates :budget_id, uniqueness: { scope: :category_id }

  monetize :budgeted_spending, :actual_spending, :vs_budgeted_spending

  class Group
    attr_reader :budget_category, :budget_subcategories

    delegate :category, to: :budget_category
    delegate :name, :color, to: :category

    def self.for(budget_categories)
      top_level_categories = budget_categories.select { |budget_category| budget_category.category.parent_id.nil? }
      top_level_categories.map do |top_level_category|
        subcategories = budget_categories.select { |bc| bc.category.parent_id == top_level_category.category_id && top_level_category.category_id.present? }
        new(top_level_category, subcategories)
      end.sort_by { |group| group.category.name }
    end

    def initialize(budget_category, budget_subcategories = [])
      @budget_category = budget_category
      @budget_subcategories = budget_subcategories
    end
  end

  def category
    super || budget.family.categories.uncategorized
  end

  def actual_spending
    category.month_total(date: budget.start_date)
  end

  def over?
    vs_actual.positive?
  end

  def within?
    vs_actual.negative? || vs_actual.zero?
  end

  def vs_actual
    actual_spending - budgeted_spending
  end

  def vs_actual_percent
    return 0 unless budgeted_spending > 0

    (actual_spending / budgeted_spending) * 100
  end

  def to_donut_segments_json
    unused_segment_id = "unused"
    overage_segment_id = "overage"

    return [ { color: "#F0F0F0", amount: 1, id: unused_segment_id } ] unless actual_amount > 0

    segments = [ { color: category.color, amount: actual_amount.amount, id: id } ]

    if overage >= 0
      segments.push({ color: "#EF4444", amount: overage.abs.amount, id: overage_segment_id })
    else
      segments.push({ color: "#F0F0F0", amount: unspent.amount, id: unused_segment_id })
    end

    segments
  end
end
