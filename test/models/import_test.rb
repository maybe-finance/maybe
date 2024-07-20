require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ImportTestHelper, ActiveJob::TestHelper

  setup do
    @empty_import = imports(:empty_import)

    @loaded_import = @empty_import.dup
    @loaded_import.update! raw_csv_str: valid_csv_str

    @import_with_header = Import.new(raw_csv_str: "column1,column2,column3\nvalue1,value2,value3")
    @import_without_header = Import.new(raw_csv_str: "121.45,value2,value3\nvalue4,value5,value6")
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
      -> { Account::Transaction.count } => 4,
      -> { Account::Entry.count } => 4,
      -> { Category.count } => 1,
      -> { Tagging.count } => 4,
      -> { Tag.count } => 2 do
      @loaded_import.publish
    end

    @loaded_import.reload

    assert @loaded_import.complete?
  end

  test "publishes a valid import with missing data" do
    @empty_import.update! raw_csv_str: valid_csv_with_missing_data
    assert_difference -> { Category.count } => 1,
                      -> { Account::Transaction.count } => 2,
                      -> { Account::Entry.count } => 2 do
      @empty_import.publish
    end

    assert_not_nil Account::Entry.find_sole_by(name: Import::FALLBACK_TRANSACTION_NAME)

    @empty_import.reload

    assert @empty_import.complete?
  end

  test "failed publish results in error status" do
    @empty_import.update! raw_csv_str: valid_csv_with_invalid_values

    assert_difference "Account::Transaction.count", 0 do
      @empty_import.publish
    end

    @empty_import.reload
    assert @empty_import.failed?
  end

  test "Import#add_headers_if_missing should not add headers if they already exist" do
    @import_with_header.add_headers_if_missing
    assert_equal "column1,column2,column3\nvalue1,value2,value3", @import_with_header.raw_csv_str
  end

  test "Import#add_headers_if_missing should add headers if they are missing" do
    @import_without_header.add_headers_if_missing
    expected_csv = "121.45,value2,value3\n121.45,value2,value3\nvalue4,value5,value6"
    assert_equal expected_csv, @import_without_header.raw_csv_str
  end

  test "Import#add_headers_if_missing should handle empty CSV string" do
    @empty_import.add_headers_if_missing
    assert_nil @empty_import.raw_csv_str
  end
end
