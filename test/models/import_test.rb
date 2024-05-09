require "test_helper"

class ImportTest < ActiveSupport::TestCase
  setup do
    @import = imports(:empty_import)
  end

  test "raw csv input cannot be empty" do
    @import.raw_csv = ""
    assert_not @import.valid?
  end

  test "raw csv input must conform to csv spec" do
    invalid_csv_format = <<-ROWS
      name,age
      "John Doe,23
      "Jane Doe",25
    ROWS

    @import.raw_csv = invalid_csv_format
    assert_not @import.valid?

    valid_csv_format = <<-ROWS
      name,age
      John,20
      Jane,23
    ROWS

    @import.raw_csv = valid_csv_format
    assert @import.valid?
  end
end
