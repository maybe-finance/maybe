require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ImportTestHelper, ActiveJob::TestHelper

  setup do
    @empty_import = imports(:empty_import)

    @loaded_import = @empty_import.dup
    @loaded_import.update! raw_csv_str: valid_csv_str
  end

  test "raw csv input must conform to csv spec" do
    @empty_import.raw_csv_str = malformed_csv_str
    assert_not @empty_import.valid?

    @empty_import.raw_csv_str = valid_csv_str
    assert @empty_import.valid?
  end

  test "can update csv value without affecting raw input" do
    assert_equal "Starbucks drink", @loaded_import.csv.table[0][1]

    prior_raw_csv_str_value = @loaded_import.raw_csv_str
    prior_normalized_csv_str_value = @loaded_import.normalized_csv_str

    @loaded_import.update_csv! \
      row_idx: 0,
      col_idx: 1,
      value: "new_category"

    assert_equal "new_category", @loaded_import.csv.table[0][1]
    assert_equal prior_raw_csv_str_value, @loaded_import.raw_csv_str
    assert_not_equal prior_normalized_csv_str_value, @loaded_import.normalized_csv_str
  end

  test "publishes later" do
    assert_enqueued_with(job: ImportJob) do
      @loaded_import.publish_later
    end
  end

  test "publishes a valid import" do
    # Import has 3 unique categories: "Food & Drink", "Income", and "Shopping" (x2)
    # Fixtures already define "Food & Drink" and "Income", so these should not be created
    # "Shopping" is a new category, but should only be created 1x during import
    assert_difference \
      -> { Transaction.count } => 4,
      -> { Transaction::Category.count } => 1,
      -> { Tagging.count } => 4,
      -> { Tag.count } => 2 do
      @loaded_import.publish
    end

    @loaded_import.reload

    assert @loaded_import.complete?
  end

  test "publishes a valid import with missing data" do
    @empty_import.update! raw_csv_str: valid_csv_with_missing_data
    assert_difference -> { Transaction::Category.count } => 1, -> { Transaction.count } => 2 do
      @empty_import.publish
    end

    assert_not_nil Transaction.find_sole_by(name: Import::FALLBACK_TRANSACTION_NAME)

    @empty_import.reload

    assert @empty_import.complete?
  end

  test "failed publish results in error status" do
    @empty_import.update! raw_csv_str: valid_csv_with_invalid_values

    assert_difference "Transaction.count", 0 do
      @empty_import.publish
    end

    @empty_import.reload
    assert @empty_import.failed?
  end
end
