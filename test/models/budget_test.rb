require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  def setup
    @family = families(:one)
    @budget = Budget.create!(
      family: @family,
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month,
      currency: "USD"
    )
  end

  test "to_donut_segments_json returns proper structure" do
    # Test with empty budget (should return single unused segment)
    segments = @budget.to_donut_segments_json
    assert_equal 1, segments.length
    assert_equal "unused", segments.first[:id]
    assert_equal "var(--budget-unallocated-fill)", segments.first[:color]
    assert_equal 1, segments.first[:amount]
  end

  test "to_donut_segments_json with categories doesn't cause N+1 queries" do
    # Create some test categories and budget categories
    category1 = @family.categories.create!(name: "Food", color: "#ff0000")
    category2 = @family.categories.create!(name: "Transport", color: "#00ff00")
    
    @budget.budget_categories.create!(category: category1, budgeted_spending: 1000, currency: "USD")
    @budget.budget_categories.create!(category: category2, budgeted_spending: 500, currency: "USD")
    
    # Mock budget to be valid
    @budget.stubs(:allocations_valid?).returns(true)
    @budget.stubs(:available_to_spend).returns(Money.new(100))
    @budget.stubs(:expense_totals).returns(
      double(category_totals: [
        double(category: double(id: category1.id), total: 800),
        double(category: double(id: category2.id), total: 300)
      ])
    )

    # Count the number of queries when generating segments
    queries_before = count_queries do
      @budget.to_donut_segments_json
    end

    # Should not cause excessive queries due to our optimization
    assert queries_before < 10, "Expected fewer than 10 queries, got #{queries_before}"
  end

  test "allocated_spending uses includes to prevent N+1 queries" do
    # Create some test categories and budget categories
    category1 = @family.categories.create!(name: "Food", color: "#ff0000")
    category2 = @family.categories.create!(name: "Transport", color: "#00ff00", parent: category1)
    
    @budget.budget_categories.create!(category: category1, budgeted_spending: 1000, currency: "USD")
    @budget.budget_categories.create!(category: category2, budgeted_spending: 500, currency: "USD")

    # Count queries when calculating allocated spending
    queries_before = count_queries do
      @budget.allocated_spending
    end

    # Should not cause excessive queries due to our optimization
    assert queries_before < 5, "Expected fewer than 5 queries, got #{queries_before}"
  end

  private

  def count_queries(&block)
    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      query_count += 1
    end
    
    block.call
    query_count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
