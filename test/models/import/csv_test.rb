require "test_helper"

class Import::CsvTest < ActiveSupport::TestCase
  include ImportTestHelper

  setup do
    @csv = Import::Csv.new(valid_csv_str)
  end

  test "cannot define validator for non-existent header" do
    assert_raises do
      @csv.define_validator "invalid", method(:validate_iso_date)
    end
  end

  test "csv with no validators is valid" do
    assert @csv.cell_valid?(0, 0)
    assert @csv.valid?
  end

  test "valid csv values" do
    @csv.define_validator "date", method(:validate_iso_date)

    assert_equal "2024-01-01", @csv.table[0][0]
    assert @csv.cell_valid?(0, 0)
    assert @csv.valid?
  end

  test "invalid csv values" do
    invalid_csv = Import::Csv.new valid_csv_with_invalid_values

    invalid_csv.define_validator "date", method(:validate_iso_date)

    assert_equal "invalid_date", invalid_csv.table[0][0]
    assert_not invalid_csv.cell_valid?(0, 0)
    assert_not invalid_csv.valid?
  end

  test "CSV with semicolon column separator" do
    csv = Import::Csv.new(valid_csv_str_with_semicolon_separator, col_sep: ";")

    assert_equal %w[ date name category tags amount ], csv.table.headers
    assert_equal 4, csv.table.size
    assert_equal "Paycheck", csv.table[3][1]
  end

  test "csv with additional columns and empty values" do
    csv = Import::Csv.new valid_csv_with_missing_data
    assert csv.valid?
  end

  test "updating a cell returns a copy of the original csv" do
    original_date = "2024-01-01"
    new_date = "2024-01-01"

    assert_equal original_date, @csv.table[0][0]
    updated = @csv.update_cell(0, 0, new_date)

    assert_equal original_date, @csv.table[0][0]
    assert_equal new_date, updated[0][0]
  end

  test "can create CSV with expected columns and field mappings with validators" do
    date_field = Import::Field.new \
      key: "date",
      label: "Date",
      validator: method(:validate_iso_date)

    name_field = Import::Field.new \
      key: "name",
      label: "Name"

    fields = [ date_field, name_field ]

    raw_csv_str = <<-ROWS
      date,Custom Field Header,extra_field
      invalid_date_value,Starbucks drink,Food
      2024-01-02,Amazon stuff,Shopping
    ROWS

    mappings = {
      "name" => "Custom Field Header"
    }

    csv = Import::Csv.create_with_field_mappings(raw_csv_str, fields, mappings)

    assert_equal %w[ date name ], csv.table.headers
    assert_equal 2, csv.table.size
    assert_equal "Amazon stuff", csv.table[1][1]
  end

  test "can create CSV with expected columns, field mappings with validators and semicolon column separator" do
    date_field = Import::Field.new \
      key: "date",
      label: "Date",
      validator: method(:validate_iso_date)

    name_field = Import::Field.new \
      key: "name",
      label: "Name"

    fields = [ date_field, name_field ]

    raw_csv_str = <<-ROWS
      date;Custom Field Header;extra_field
      invalid_date_value;Starbucks drink;Food
      2024-01-02;Amazon stuff;Shopping
    ROWS

    mappings = {
      "name" => "Custom Field Header"
    }

    csv = Import::Csv.create_with_field_mappings(raw_csv_str, fields, mappings, ";")

    assert_equal %w[ date name ], csv.table.headers
    assert_equal 2, csv.table.size
    assert_equal "Amazon stuff", csv.table[1][1]
  end

  private

    def validate_iso_date(value)
      Date.iso8601(value)
      true
    rescue
      false
    end
end
