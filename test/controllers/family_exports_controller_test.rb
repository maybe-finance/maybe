require "test_helper"

class FamilyExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:family_admin)
    @non_admin = users(:family_member)
    @family = @admin.family

    sign_in @admin
  end

  test "non-admin cannot access exports" do
    sign_in @non_admin

    get new_family_export_path
    assert_redirected_to root_path

    post family_exports_path
    assert_redirected_to root_path

    get family_exports_path
    assert_redirected_to root_path
  end

  test "admin can view export modal" do
    get new_family_export_path
    assert_response :success
    assert_select "h2", text: "Export your data"
  end

  test "admin can create export" do
    assert_enqueued_with(job: FamilyDataExportJob) do
      post family_exports_path
    end

    assert_redirected_to settings_profile_path
    assert_equal "Export started. You'll be able to download it shortly.", flash[:notice]

    export = @family.family_exports.last
    assert_equal "pending", export.status
  end

  test "admin can view export list" do
    export1 = @family.family_exports.create!(status: "completed")
    export2 = @family.family_exports.create!(status: "processing")

    get family_exports_path
    assert_response :success

    assert_match export1.filename, response.body
    assert_match "Exporting...", response.body
  end

  test "admin can download completed export" do
    export = @family.family_exports.create!(status: "completed")
    export.export_file.attach(
      io: StringIO.new("test zip content"),
      filename: "test.zip",
      content_type: "application/zip"
    )

    get download_family_export_path(export)
    assert_redirected_to(/rails\/active_storage/)
  end

  test "cannot download incomplete export" do
    export = @family.family_exports.create!(status: "processing")

    get download_family_export_path(export)
    assert_redirected_to settings_profile_path
    assert_equal "Export not ready for download", flash[:alert]
  end
end
