class Transaction::Category < ApplicationRecord
  has_many :transactions
  belongs_to :family

  before_update :clear_internal_category, if: :name_changed?

  DEFAULT_CATEGORIES = [
    { internal_category: "income", color: "#fd7f6f", icon: "piggy-bank" },
    { internal_category: "food_and_drink", color: "#7eb0d5", icon: "utensils" },
    { internal_category: "entertainment", color: "#b2e061", icon: "drama" },
    { internal_category: "personal_care", color: "#bd7ebe", icon: "person-standing" },
    { internal_category: "general_services", color: "#ffb55a", icon: "cog" },
    { internal_category: "auto_and_transport", color: "#ffee65", icon: "car" },
    { internal_category: "rent_and_utilities", color: "#beb9db", icon: "home" },
    { internal_category: "home_improvement", color: "#fdcce5", icon: "hand-coins" }
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
      icon: c[:icon],
      family_id:
    } }
    self.insert_all(categories)
  end

  private

  def clear_internal_category
    self.internal_category = nil
  end
end
