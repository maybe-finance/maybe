require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "publishes later" do
    import = imports(:transaction)

    import.stubs(:publishable?).returns(true)

    assert_enqueued_with job: ImportJob, args: [ import ] do
      import.publish_later
    end

    assert_equal "importing", import.reload.status
  end

  test "raises if not publishable" do
    import = imports(:transaction)

    import.stubs(:publishable?).returns(false)

    assert_raises(RuntimeError, "Import is not publishable") do
      import.publish_later
    end
  end
end
