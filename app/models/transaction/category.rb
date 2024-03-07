class Transaction::Category < ApplicationRecord
  has_many :transactions
  belongs_to :family

  before_update :clear_internal_category, if: :name_changed?

  DEFAULT_CATEGORIES = [
    { internal_category: "income", color: "#fd7f6f" },
    { internal_category: "food_and_drink", color: "#7eb0d5" },
    { internal_category: "entertainment", color: "#b2e061" },
    { internal_category: "personal_care", color: "#bd7ebe" },
    { internal_category: "general_services", color: "#ffb55a" },
    { internal_category: "auto_and_transport", color: "#ffee65" },
    { internal_category: "rent_and_utilities", color: "#beb9db" },
    { internal_category: "home_improvement", color: "#fdcce5" }
  ]

  def self.create_default_categories(family)
    if family.transaction_categories.size > 0
      raise ArgumentError, "Family already has some categories"
    end

    family_id = family.id
    categories = self::DEFAULT_CATEGORIES.map { |c| {
      name: I18n.t("transaction.default_category.#{c[:internal_category]}"),
      internal_category: c[:internal_category],
      color: c[:color],
      family_id:
    } }
    self.insert_all(categories)
  end

  private

  def clear_internal_category
    self.internal_category = nil
  end
end
