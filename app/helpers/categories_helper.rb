module CategoriesHelper
  def null_category
    Category.new \
      name: "Uncategorized",
      color: Category::UNCATEGORIZED_COLOR
  end

  def family_categories
    [null_category].concat(Current.family.categories.alphabetically)
  end
end
