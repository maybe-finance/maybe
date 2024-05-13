class AddStatusToImport < ActiveRecord::Migration[7.2]
  def change
    create_enum :import_status, %w[pending completed]

    change_table :imports do |t|
      t.enum :status, enum_type: :import_status, default: "pending"
    end
  end
end
