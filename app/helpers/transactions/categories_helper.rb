module Transactions::CategoriesHelper
  def null_category
    Transaction::Category.new \
      name: "Uncategorized",
      color: Transaction::Category::UNCATEGORIZED_COLOR
  end
end
