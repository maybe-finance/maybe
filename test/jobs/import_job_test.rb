require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  test "import is published" do
    import = imports(:transaction)
    import.expects(:publish).once

    ImportJob.perform_now(import)
  end
end
