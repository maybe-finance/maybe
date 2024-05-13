require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ImportTestHelper, ActiveJob::TestHelper

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
      "name" => "name",
      "category" => "category",
      "amount" => "amount"
    }

    assert @import.valid?
  end

  test "column mappings must find a valid header in the input csv" do
    @import.raw_csv = valid_csv_str

    @import.column_mappings = {
      "date" => "invalid_date_key_that_does_not_match_input_csv",
      "name" => "another_invalid_key",
      "category" => "category",
      "amount" => "amount"
    }

    assert_not @import.valid?
    assert_includes @import.errors.full_messages, "column map has key date, but could not find date in raw csv input"
    assert_includes @import.errors.full_messages, "column map has key name, but could not find name in raw csv input"
  end

  test "publishes later" do
    assert_enqueued_with(job: ImportJob) do
      @import.publish_later
    end
  end

  test "publishes a valid import" do
    @import.rows.insert_all(
      [
        { date: "2024-01-01", name: "Test row", category: "category", amount: "20" }
      ]
    )

    assert_difference "Transaction.count", 1 do
      @import.publish
    end

    @import.reload

    assert @import.complete?
  end

  test "failed publish results in error status" do
    @import.rows.insert_all(
      [
        { date: "invalid date", name: "Test row", category: "category", amount: "invalid numeric" }
      ]
    )

    assert_difference "Transaction.count", 0 do
      @import.publish
    end

    @import.reload
    assert @import.failed?
  end
end
