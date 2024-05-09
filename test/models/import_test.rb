require "test_helper"

class ImportTest < ActiveSupport::TestCase
  setup do
    @import = imports(:empty_import)

    @valid_csv = <<-ROWS
      name,age
      John,20
      Jane,23
    ROWS

    @invalid_csv = <<-ROWS
      name,age
      "John Doe,23
      "Jane Doe",25
    ROWS
  end

  test "raw csv input cannot be empty" do
    @import.raw_csv = ""
    assert_not @import.valid?
  end

  test "raw csv input must conform to csv spec" do
    @import.raw_csv = @invalid_csv
    assert_not @import.valid?

    @import.raw_csv = @valid_csv
    assert @import.valid?
  end

  test "cannot modify a completed import" do
    import = imports(:completed_import)

    # Placeholder implementation
    import.stubs(:complete?).returns(true)

    assert import.complete?
    import.raw_csv = @valid_csv

    saved = import.save

    assert_not saved
    assert_includes import.errors.full_messages, "Update not allowed on a completed import."
  end
end
