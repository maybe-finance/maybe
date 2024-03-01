class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :category

  before_validation :assign_category
  after_commit :sync_account

  private

    def sync_account
      self.account.sync_later
    end

    def assign_category
      category_type = self.amount < 0 ? "expense" : "income"
      self.category = self.account.family.categories.find_by(category_type:, is_default: true) if category.blank?
    end
end
