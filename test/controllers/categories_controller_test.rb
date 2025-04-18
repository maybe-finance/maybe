require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @transaction = transactions :one
  end

  test "index" do
    get categories_url
    assert_response :success
  end

  test "new" do
    get new_category_url
    assert_response :success
  end

  test "create" do
    color = Category::COLORS.sample

    assert_difference "Category.count", +1 do
      post categories_url, params: {
        category: {
          name: "New Category",
          color: color } }
    end

    new_category = Category.order(:created_at).last

    assert_redirected_to categories_url
    assert_equal "New Category", new_category.name
    assert_equal color, new_category.color
  end

  test "create fails if name is not unique" do
    assert_no_difference "Category.count" do
      post categories_url, params: {
        category: {
          name: categories(:food_and_drink).name,
          color: Category::COLORS.sample } }
    end

    assert_response :unprocessable_entity
  end

  test "create and assign to transaction" do
    color = Category::COLORS.sample

    assert_difference "Category.count", +1 do
      post categories_url, params: {
        transaction_id: @transaction.id,
        category: {
          name: "New Category",
          color: color } }
    end

    new_category = Category.order(:created_at).last

    assert_redirected_to categories_url
    assert_equal "New Category", new_category.name
    assert_equal color, new_category.color
    assert_equal @transaction.reload.category, new_category
  end

  test "edit" do
    get edit_category_url(categories(:food_and_drink))
    assert_response :success
  end

  test "update" do
    new_color = Category::COLORS.without(categories(:income).color).sample

    assert_changes -> { categories(:income).name }, to: "New Name" do
      assert_changes -> { categories(:income).reload.color }, to: new_color do
        patch category_url(categories(:income)), params: {
          category: {
            name: "New Name",
            color: new_color } }
      end
    end

    assert_redirected_to categories_url
  end

  test "bootstrap" do
    assert_difference "Category.count", 12 do
      post bootstrap_categories_url
    end

    assert_redirected_to categories_url
  end
end
