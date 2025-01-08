class BudgetCategory < ApplicationRecord
  belongs_to :budget
  belongs_to :category

  validates :budget_id, uniqueness: { scope: :category_id }
end
