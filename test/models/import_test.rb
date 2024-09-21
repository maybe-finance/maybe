require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ImportTestHelper, ActiveJob::TestHelper

  setup do
    @empty_import = imports(:empty_import)

    @loaded_import = @empty_import.dup
    @loaded_import.update! raw_file_str: valid_csv_str
  end

  test "validates the correct col_sep" do
    assert_equal ",", @empty_import.col_sep

    assert @empty_import.valid?

    @empty_import.col_sep = "invalid"
    assert @empty_import.invalid?

    @empty_import.col_sep = ","
    assert @empty_import.valid?

    @empty_import.col_sep = ";"
    assert @empty_import.valid?
  end

  test "raw csv input must conform to csv spec" do
    @empty_import.raw_file_str = malformed_csv_str
    assert_not @empty_import.valid?

    @empty_import.raw_file_str = valid_csv_str
    assert @empty_import.valid?
  end
end
