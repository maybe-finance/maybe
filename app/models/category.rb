class Category < ApplicationRecord
  has_many :transactions
  belongs_to :family

  before_destroy :can_destroy?, prepend: true, unless: :destroyed_by_association

  enum :category_type, { income: "income", expense: "expense" }

  private

  def can_destroy?
    if self.is_default?
      self.errors.add(:base, "Default categories cannot be deleted")
      throw :abort
    end
  end
end
