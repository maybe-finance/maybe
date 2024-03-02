require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  def setup
    @dylan_family = families(:dylan_family)
  end

  test "should not allow default categories to be deleted" do
    # creating a fresh category to ensure there are no transactions referencing it
    category = Category.create(name: "test", color: "#abbd9a", category_type: :income, is_default: true, family: @dylan_family)
    category.destroy

    assert_not_nil @dylan_family.categories.find_by(id: category.id)
  end

  test "should allow custom categories to be deleted" do
    # creating a fresh category to ensure there are no transactions referencing it
    category = Category.create(name: "test", color: "#abbd9a", category_type: :income, is_default: false, family: @dylan_family)
    category.destroy

    assert_nil @dylan_family.categories.find_by(id: category.id)
  end
end
