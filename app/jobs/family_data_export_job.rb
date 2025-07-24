class FamilyDataExportJob < ApplicationJob
  queue_as :default

  def perform(family_export)
    family_export.update!(status: :processing)

    exporter = Family::DataExporter.new(family_export.family)
    zip_file = exporter.generate_export

    family_export.export_file.attach(
      io: zip_file,
      filename: family_export.filename,
      content_type: "application/zip"
    )

    family_export.update!(status: :completed)
  rescue => e
    Rails.logger.error "Family export failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    family_export.update!(status: :failed)
  end
end
