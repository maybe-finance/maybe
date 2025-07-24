require "test_helper"

class FamilyDataExportJobTest < ActiveJob::TestCase
  setup do
    @family = families(:dylan_family)
    @export = @family.family_exports.create!
  end

  test "marks export as processing then completed" do
    assert_equal "pending", @export.status

    perform_enqueued_jobs do
      FamilyDataExportJob.perform_later(@export)
    end

    @export.reload
    assert_equal "completed", @export.status
    assert @export.export_file.attached?
  end

  test "marks export as failed on error" do
    # Mock the exporter to raise an error
    Family::DataExporter.any_instance.stubs(:generate_export).raises(StandardError, "Export failed")

    perform_enqueued_jobs do
      FamilyDataExportJob.perform_later(@export)
    end

    @export.reload
    assert_equal "failed", @export.status
  end
end
