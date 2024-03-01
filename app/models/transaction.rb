class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :category

  before_validation :assign_default_category
  after_commit :sync_account

  private

    def sync_account
      self.account.sync_later
    end

    def assign_default_category
      if category.blank?
        category_type = self.amount < 0 ? "expense" : "income"
        self.category = self.account.family.categories.find_by(category_type:, is_default: true)
      end
    end
end
