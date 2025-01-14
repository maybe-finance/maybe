class BudgetCategory < ApplicationRecord
  include Monetizable

  belongs_to :budget
  belongs_to :category, optional: true

  validates :budget_id, uniqueness: { scope: :category_id }

  monetize :budgeted_amount

  class Group
    attr_reader :budget_category, :budget_subcategories

    delegate :category, to: :budget_category
    delegate :name, :color, to: :category

    def self.for(budget_categories)
      top_level_categories = budget_categories.select { |budget_category| budget_category.category.parent_id.nil? }
      top_level_categories.map do |top_level_category|
        subcategories = budget_categories.select { |bc| bc.category.parent_id == top_level_category.category_id && top_level_category.category_id.present? }
        new(top_level_category, subcategories)
      end
    end

    def initialize(budget_category, budget_subcategories = [])
      @budget_category = budget_category
      @budget_subcategories = budget_subcategories
    end
  end

  def category
    super || budget.family.categories.uncategorized
  end

  def actual_amount
    category.month_total(date: budget.start_date)
  end

  def over_budget?
    actual_amount > budget.budgeted_amount_money
  end

  def overage_amount
    actual_amount - budgeted_amount_money
  end

  def overage
    actual_amount - budgeted_amount_money
  end

  def unspent
    overage * -1
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
