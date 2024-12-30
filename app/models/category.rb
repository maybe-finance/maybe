class Category < ApplicationRecord
  has_many :transactions, dependent: :nullify, class_name: "Account::Transaction"
  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"

  belongs_to :family

  has_many :budget_categories, dependent: :destroy
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id
  belongs_to :parent, class_name: "Category", optional: true

  enum :classification, { expense: "expense", income: "income", transfer: "transfer", payment: "payment" }

  validates :name, :color, :family, presence: true
  validates :name, uniqueness: { scope: :family_id }

  validate :category_level_limit

  scope :alphabetically, -> { order(:name) }

  COLORS = %w[#e99537 #4da568 #6471eb #db5a54 #df4e92 #c44fe9 #eb5429 #61c9ea #805dee #6ad28a]

  UNCATEGORIZED_COLOR = "#737373"

  class Group
    attr_reader :category, :subcategories

    delegate :name, :color, to: :category

    def self.for(categories)
      categories.select { |category| category.parent_id.nil? }.map do |category|
        new(category, category.subcategories)
      end
    end

    def initialize(category, subcategories = nil)
      @category = category
      @subcategories = subcategories || []
    end
  end

  class << self
    def bootstrap_defaults
      default_categories.each do |name, color|
        find_or_create_by!(name: name) do |category|
          category.color = color
        end
      end
    end

    private
      def default_categories
        [
          [ "Income", "#e99537" ],
          [ "Loan Payments", "#6471eb" ],
          [ "Bank Fees", "#db5a54" ],
          [ "Entertainment", "#df4e92" ],
          [ "Food & Drink", "#c44fe9" ],
          [ "Groceries", "#eb5429" ],
          [ "Dining Out", "#61c9ea" ],
          [ "General Merchandise", "#805dee" ],
          [ "Clothing & Accessories", "#6ad28a" ],
          [ "Electronics", "#e99537" ],
          [ "Healthcare", "#4da568" ],
          [ "Insurance", "#6471eb" ],
          [ "Utilities", "#db5a54" ],
          [ "Transportation", "#df4e92" ],
          [ "Gas & Fuel", "#c44fe9" ],
          [ "Education", "#eb5429" ],
          [ "Charitable Donations", "#61c9ea" ],
          [ "Subscriptions", "#805dee" ]
        ]
      end
  end

  def replace_and_destroy!(replacement)
    transaction do
      transactions.update_all category_id: replacement&.id
      destroy!
    end
  end

  def subcategory?
    parent.present?
  end

  private
    def category_level_limit
      if subcategory? && parent.subcategory?
        errors.add(:parent, "can't have more than 2 levels of subcategories")
      end
    end
end
