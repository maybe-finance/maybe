require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  include ImportTestHelper

  test "import is published" do
    import = imports(:empty_import)
    import.update! \
      raw_csv: valid_csv_str,
      column_mappings: import.default_column_mappings

    assert import.pending?

    perform_enqueued_jobs do
      ImportJob.perform_later(import)
    end

    assert import.reload.complete?
  end
end
