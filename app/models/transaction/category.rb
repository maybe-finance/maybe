class Transaction::Category < ApplicationRecord
  has_many :transactions
  belongs_to :family

  validates :name, :color, :family, presence: true

  before_update :clear_internal_category, if: :name_changed?

  DEFAULT_CATEGORIES = [
    { internal_category: "income", color: "#e99537" },
    { internal_category: "food_and_drink", color: "#4da568" },
    { internal_category: "entertainment", color: "#6471eb" },
    { internal_category: "personal_care", color: "#db5a54" },
    { internal_category: "general_services", color: "#df4e92" },
    { internal_category: "auto_and_transport", color: "#c44fe9" },
    { internal_category: "rent_and_utilities", color: "#eb5429" },
    { internal_category: "home_improvement", color: "#61c9ea" }
  ]

  def self.ransackable_attributes(auth_object = nil)
    %w[name id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

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
