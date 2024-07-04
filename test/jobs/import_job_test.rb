require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  include ImportTestHelper

  test "import is published" do
    import = imports(:empty_import)

    Import.any_instance.expects(:publish).once

    perform_enqueued_jobs do
      ImportJob.perform_later(import)
    end
  end
end
