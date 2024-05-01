require "test_helper"

class Transaction::CategoryTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)
  end

  test "create_default_categories should generate categories if none exist" do
    @family.accounts.destroy_all
    @family.transaction_categories.destroy_all
    assert_difference "Transaction::Category.count", Transaction::Category::DEFAULT_CATEGORIES.size do
      Transaction::Category.create_default_categories(@family)
    end
  end

  test "create_default_categories should raise when there are existing categories" do
    assert_raises(ArgumentError) do
      Transaction::Category.create_default_categories(@family)
    end
  end

  test "updating name should clear the internal_category field" do
    category = Transaction::Category.take
    assert_changes "category.reload.internal_category", to: nil do
      category.update_attribute(:name, "new name")
    end
  end

  test "updating other field than name should not clear the internal_category field" do
    category = Transaction::Category.take
    assert_no_changes "category.reload.internal_category" do
      category.update_attribute(:color, "#000")
    end
  end

  test "replacing and destroying" do
    transctions = transaction_categories(:food_and_drink).transactions.to_a

    transaction_categories(:food_and_drink).replace_and_destroy!(transaction_categories(:income))

    assert_equal transaction_categories(:income), transactions.map { |t| t.reload.category }.uniq.first
  end

  test "replacing with nil should nullify the category" do
    transactions = transaction_categories(:food_and_drink).transactions.to_a

    transaction_categories(:food_and_drink).replace_and_destroy!(nil)

    assert_nil transactions.map { |t| t.reload.category }.uniq.first
  end
end
