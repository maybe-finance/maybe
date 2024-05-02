require "test_helper"

class Transactions::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "index" do
    get transaction_categories_url
    assert_response :success
  end

  test "new" do
    get new_transaction_category_url
    assert_response :success
  end

  test "create" do
    color = Transaction::Category::COLORS.sample

    assert_difference "Transaction::Category.count", +1 do
      post transaction_categories_url, params: {
        transaction_category: {
          name: "New Category",
          color: color } }
    end

    new_category = Transaction::Category.order(:created_at).last

    assert_redirected_to transactions_url
    assert_equal "New Category", new_category.name
    assert_equal color, new_category.color
  end

  test "create and assign to transaction" do
    color = Transaction::Category::COLORS.sample

    assert_difference "Transaction::Category.count", +1 do
      post transaction_categories_url, params: {
        transaction_id: transactions(:checking_one).id,
        transaction_category: {
          name: "New Category",
          color: color } }
    end

    new_category = Transaction::Category.order(:created_at).last

    assert_redirected_to transactions_url
    assert_equal "New Category", new_category.name
    assert_equal color, new_category.color
    assert_equal transactions(:checking_one).reload.category, new_category
  end

  test "edit" do
    get edit_transaction_category_url(transaction_categories(:food_and_drink))
    assert_response :success
  end

  test "update" do
    new_color = Transaction::Category::COLORS.without(transaction_categories(:income).color).sample

    assert_changes -> { transaction_categories(:income).name }, to: "New Name" do
      assert_changes -> { transaction_categories(:income).reload.color }, to: new_color do
        patch transaction_category_url(transaction_categories(:income)), params: {
          transaction_category: {
            name: "New Name",
            color: new_color } }
      end
    end

    assert_redirected_to transactions_url
  end
end
