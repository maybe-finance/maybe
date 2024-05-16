require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ImportTestHelper, ActiveJob::TestHelper

  setup do
    @import = imports(:empty_import)
  end

  test "raw csv input must conform to csv spec" do
    @import.raw_csv_str = malformed_csv_str
    assert_not @import.valid?

    @import.raw_csv_str = valid_csv_str
    assert @import.valid?
  end

  test "can update csv value without affecting raw input" do
    @import.update! raw_csv_str: valid_csv_str

    assert_equal "Starbucks drink", @import.csv.table[0][1]

    prior_raw_csv_str_value = @import.raw_csv_str
    prior_normalized_csv_str_value = @import.normalized_csv_str

    @import.update_csv! \
      row_idx: 0,
      col_idx: 1,
      value: "new_category"

    assert_equal "new_category", @import.csv.table[0][1]
    assert_equal prior_raw_csv_str_value, @import.raw_csv_str
    assert_not_equal prior_normalized_csv_str_value, @import.normalized_csv_str
  end

  test "publishes later" do
    assert_enqueued_with(job: ImportJob) do
      @import.publish_later
    end
  end

  test "publishes a valid import" do
    @import.update! raw_csv_str: valid_csv_str

    assert_difference "Transaction.count", 2 do
      @import.publish
    end

    @import.reload

    assert @import.complete?
  end

  test "failed publish results in error status" do
    @import.update! raw_csv_str: valid_csv_with_invalid_values

    assert_difference "Transaction.count", 0 do
      @import.publish
    end

    @import.reload
    assert @import.failed?
  end
end
