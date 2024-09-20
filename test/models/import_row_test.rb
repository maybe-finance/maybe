require "test_helper"

class ImportRowTest < ActiveSupport::TestCase
  setup do
    @import_row = import_rows(:completed_import_row_one)
  end

  test "skips validations when creating a row" do
    new_import_row = Import::Row.new(
      import: imports(:empty_import),
      date: "invalid_date",
      amount: "invalid_amount"
    )

    assert new_import_row.valid?
  end


  test "accepts valid dates and amounts" do
    @import_row.date = "2024-09-21"
    @import_row.amount = 99

    assert @import_row.valid?
  end

  test "import row must have a date" do
    @import_row.date = nil

    assert @import_row.invalid?
  end

  test "import row must have an amount" do
    @import_row.amount = nil

    assert @import_row.invalid?
  end

  test "import row amount must be bigdecimal" do
    @import_row.amount = "invalid_amount"

    assert @import_row.invalid?
  end

  test "import row date must be iso 8601" do
    @import_row.amount = "invalid_date"

    assert @import_row.invalid?
  end
end
