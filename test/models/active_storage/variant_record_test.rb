require "test_helper"

module ActiveStorage
  class VariantRecordTest < ActiveSupport::TestCase
    test "should delete all variant records without errors" do
      assert_nothing_raised do
        ActiveStorage::VariantRecord.delete_all
      end
    end

    test "should actually remove variant records from database" do
      # Create a test variant record
      blob = ActiveStorage::Blob.create!(
        key: "test",
        filename: "test.jpg",
        content_type: "image/jpeg",
        metadata: {},
        service_name: "test",
        byte_size: 1
      )

      variant_record = ActiveStorage::VariantRecord.create!(
        blob: blob,
        variation_digest: "test_digest"
      )

      assert_difference "ActiveStorage::VariantRecord.count", -1 do
        ActiveStorage::VariantRecord.delete_all
      end
    end
  end
end
