module CategoriesHelper
  def null_category
    Category.new \
      name: "Uncategorized",
      color: Category::UNCATEGORIZED_COLOR
  end

  def transfer_category
    Category.new \
      name: "Transfer / Payment",
      color: Category::TRANSFER_COLOR
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
