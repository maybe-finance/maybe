require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ImportTestHelper

  setup do
    @import = imports(:empty_import)
  end

  test "raw csv input cannot be empty" do
    @import.raw_csv = ""
    assert_not @import.valid?
  end

  test "raw csv input must conform to csv spec" do
    @import.raw_csv = malformed_csv_str
    assert_not @import.valid?

    @import.raw_csv = valid_csv_str
    assert @import.valid?
  end

  test "raw csv input must have at least 4 columns" do
    @import.raw_csv = insufficient_columns_csv_str
    assert_not @import.valid?
    assert_includes @import.errors.full_messages, "Raw csv must have at least 4 columns"
  end

  test "column mappings must have all required keys" do
    @import.raw_csv = valid_csv_str
    @import.column_mappings = {
      "date" => "date"
    }

    assert_not @import.valid?

    @import.column_mappings = {
      "date" => "date",
      "merchant" => "merchant",
      "category" => "category",
      "amount" => "amount"
    }

    assert @import.valid?
  end

  test "column mappings must find a valid header in the input csv" do
    @import.raw_csv = valid_csv_str

    @import.column_mappings = {
      "date" => "invalid_date_key_that_does_not_match_input_csv",
      "merchant" => "another_invalid_key",
      "category" => "category",
      "amount" => "amount"
    }

    assert_not @import.valid?
    assert_includes @import.errors.full_messages, "column map has key date, but could not find date in raw csv input"
    assert_includes @import.errors.full_messages, "column map has key merchant, but could not find merchant in raw csv input"
  end

  test "can update a cell value" do
    import = imports(:empty_import)
    import.update! raw_csv: valid_csv_str

    assert_equal "Starbucks", import.parsed_csv[0][1]

    import.update_cell! \
      row_idx: 0,
      col_idx: 1,
      value: "new_merchant"

    assert_equal "new_merchant", import.parsed_csv[0][1]
  end

  test "cannot modify a completed import" do
    import = imports(:completed_import)

    # Placeholder implementation
    import.stubs(:complete?).returns(true)

    assert import.complete?
    import.raw_csv = valid_csv_str

    saved = import.save

    assert_not saved
    assert_includes import.errors.full_messages, "Update not allowed on a completed import."
  end
end
