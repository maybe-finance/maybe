class Budget < ApplicationRecord
  belongs_to :family
  has_many :budget_categories, dependent: :destroy
end
