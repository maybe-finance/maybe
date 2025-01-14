module CategoriesHelper
  def null_category
    Category.new \
      name: "Uncategorized",
      color: Category::UNCATEGORIZED_COLOR
  end

  def transfer_category
    Category.new \
      name: "Transfer",
      color: Category::TRANSFER_COLOR,
      lucide_icon: "arrow-right-left"
  end

  def payment_category
    Category.new \
      name: "Payment",
      color: Category::PAYMENT_COLOR,
      lucide_icon: "arrow-right"
  end

  def trade_category
    Category.new \
      name: "Trade",
      color: Category::TRADE_COLOR
  end

  def family_categories
    [ null_category ].concat(Current.family.categories.alphabetically)
  end
end
