class Category < ApplicationRecord
  has_many :transactions, dependent: :nullify, class_name: "Account::Transaction"
  belongs_to :family

  validates :name, :color, :family, presence: true

  before_update :clear_internal_category, if: :name_changed?

  scope :alphabetically, -> { order(:name) }

  COLORS = %w[#e99537 #4da568 #6471eb #db5a54 #df4e92 #c44fe9 #eb5429 #61c9ea #805dee #6ad28a]

  UNCATEGORIZED_COLOR = "#737373"

  DEFAULT_CATEGORIES = [
    { internal_category: "income", color: COLORS[0] },
    { internal_category: "food_and_drink", color: COLORS[1] },
    { internal_category: "entertainment", color: COLORS[2] },
    { internal_category: "personal_care", color: COLORS[3] },
    { internal_category: "general_services", color: COLORS[4] },
    { internal_category: "auto_and_transport", color: COLORS[5] },
    { internal_category: "rent_and_utilities", color: COLORS[6] },
    { internal_category: "home_improvement", color: COLORS[7] }
  ]

  def self.create_default_categories(family)
    if family.categories.size > 0
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

  def replace_and_destroy!(replacement)
    transaction do
      transactions.update_all category_id: replacement&.id
      destroy!
    end
  end

  private

    def clear_internal_category
      self.internal_category = nil
    end
end
