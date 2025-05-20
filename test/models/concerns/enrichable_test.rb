require "test_helper"

class EnrichableTest < ActiveSupport::TestCase
  setup do
    @enrichable = accounts(:depository)
  end

  test "can enrich multiple attributes" do
    assert_difference "DataEnrichment.count", 2 do
      @enrichable.enrich_attributes({ name: "Updated Checking", balance: 6_000 }, source: "plaid")
    end

    assert_equal "Updated Checking", @enrichable.name
    assert_equal 6_000, @enrichable.balance.to_d
  end

  test "can enrich a single attribute" do
    assert_difference "DataEnrichment.count", 1 do
      @enrichable.enrich_attribute(:name, "Single Update", source: "ai")
    end

    assert_equal "Single Update", @enrichable.name
  end

  test "can lock an attribute" do
    refute @enrichable.locked?(:name)

    @enrichable.lock_attr!(:name)
    assert @enrichable.locked?(:name)
  end

  test "can unlock an attribute" do
    @enrichable.lock_attr!(:name)
    assert @enrichable.locked?(:name)

    @enrichable.unlock_attr!(:name)
    refute @enrichable.locked?(:name)
  end

  test "can lock saved attributes" do
    @enrichable.name = "User Override"
    @enrichable.balance = 1_234
    @enrichable.save!

    @enrichable.lock_saved_attributes!

    assert @enrichable.locked?(:name)
    assert @enrichable.locked?(:balance)
  end

  test "does not enrich locked attributes" do
    original_name = @enrichable.name

    @enrichable.lock_attr!(:name)

    assert_no_difference "DataEnrichment.count" do
      @enrichable.enrich_attribute(:name, "Should Not Change", source: "plaid")
    end

    assert_equal original_name, @enrichable.reload.name
  end

  test "enrichable? reflects lock state" do
    assert @enrichable.enrichable?(:name)

    @enrichable.lock_attr!(:name)

    refute @enrichable.enrichable?(:name)
  end

  test "enrichable scope includes and excludes records based on lock state" do
    # Initially, the record should be enrichable for :name
    assert_includes Account.enrichable(:name), @enrichable

    @enrichable.lock_attr!(:name)

    refute_includes Account.enrichable(:name), @enrichable
  end
end
