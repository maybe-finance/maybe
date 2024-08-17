require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  include ImportTestHelper

  test "import is published" do
    import = imports(:empty_import)
    import.update! raw_file_str: valid_csv_str

    assert import.pending?

    perform_enqueued_jobs do
      ImportJob.perform_later(import)
    end

    assert import.reload.complete?
    assert import.account.balances.present?
  end
end
