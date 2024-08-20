class AddRawTypeAndPdfRegexToImport < ActiveRecord::Migration[7.2]
  def change
    # sets default from existing records, and then removes the default
    add_column :imports, :raw_type, :string, default: 'csv', null: false
    change_column_default :imports, :raw_type, from: 'csv', to: nil
    # adds a pdf regex
    add_reference :imports, :pdf_regex, foreign_key: true, type: :uuid
  end
end
