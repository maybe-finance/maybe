module CategoriesHelper
  def null_category
    Category.new \
      name: "Uncategorized",
      color: Category::UNCATEGORIZED_COLOR
  end
end
