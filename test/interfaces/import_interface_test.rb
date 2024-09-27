require "test_helper"

module ImportInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "import interface" do
    assert_respond_to @subject, :publish
    assert_respond_to @subject, :publish_later
    assert_respond_to @subject, :generate_rows_from_csv
    assert_respond_to @subject, :csv_rows
    assert_respond_to @subject, :csv_headers
    assert_respond_to @subject, :csv_sample
    assert_respond_to @subject, :uploaded?
    assert_respond_to @subject, :configured?
    assert_respond_to @subject, :cleaned?
    assert_respond_to @subject, :publishable?
    assert_respond_to @subject, :importing?
    assert_respond_to @subject, :complete?
    assert_respond_to @subject, :failed?
  end

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

  test "handles publish errors" do
    import = imports(:transaction)

    import.stubs(:publishable?).returns(true)
    import.stubs(:import!).raises(StandardError, "Failed to publish")

    assert_nil import.error

    import.publish

    assert_equal "Failed to publish", import.error
    assert_equal "failed", import.status
  end
end
