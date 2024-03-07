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
end
