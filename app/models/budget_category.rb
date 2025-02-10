class BudgetCategory < ApplicationRecord
  include Monetizable

  belongs_to :budget
  belongs_to :category

  validates :budget_id, uniqueness: { scope: :category_id }

  monetize :budgeted_spending, :actual_spending, :available_to_spend

  class Group
    attr_reader :budget_category, :budget_subcategories

    delegate :category, to: :budget_category
    delegate :name, :color, to: :category

    def self.for(budget_categories)
      top_level_categories = budget_categories.select { |budget_category| budget_category.category.parent_id.nil? }
      top_level_categories.map do |top_level_category|
        subcategories = budget_categories.select { |bc| bc.category.parent_id == top_level_category.category_id && top_level_category.category_id.present? }
        new(top_level_category, subcategories.sort_by { |subcategory| subcategory.category.name })
      end.sort_by { |group| group.category.name }
    end

    def initialize(budget_category, budget_subcategories = [])
      @budget_category = budget_category
      @budget_subcategories = budget_subcategories
    end
  end

  class << self
    def uncategorized
      new(
        id: Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "uncategorized"),
        category: nil,
      )
    end
  end

  def initialized?
    budget.initialized?
  end

  def category
    super || budget.family.categories.uncategorized
  end

  def subcategory?
    category.parent_id.present?
  end

  def actual_spending
    category.month_total(date: budget.start_date)
  end

  def available_to_spend
    (budgeted_spending || 0) - actual_spending
  end

  def percent_of_budget_spent
    return 0 unless budgeted_spending > 0

    (actual_spending / budgeted_spending) * 100
  end

  def to_donut_segments_json
    unused_segment_id = "unused"
    overage_segment_id = "overage"

    return [ { color: "#F0F0F0", amount: 1, id: unused_segment_id } ] unless actual_spending > 0

    segments = [ { color: category.color, amount: actual_spending, id: id } ]

    if available_to_spend.negative?
      segments.push({ color: "#EF4444", amount: available_to_spend.abs, id: overage_segment_id })
    else
      segments.push({ color: "#F0F0F0", amount: available_to_spend, id: unused_segment_id })
    end

    segments
  end

  def siblings
    budget.budget_categories.select { |bc| bc.category.parent_id == category.parent_id && bc.id != id }
  end

  def max_allocation
    return nil unless subcategory?
  
    parent_budget = budget.budget_categories.find { |bc| bc.category.id == category.parent_id }&.budgeted_spending
    siblings_budget = siblings.sum(&:budgeted_spending)
  
    [ parent_budget - siblings_budget, 0 ].max
  end

end
