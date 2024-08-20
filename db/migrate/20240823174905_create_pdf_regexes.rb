class CreatePdfRegexes < ActiveRecord::Migration[7.2]
  def change
    create_table :pdf_regexes, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :transaction_line_regex_str, null: false
      t.string :metadata_regex_str
      t.string :pdf_transaction_date_format, null: false
      t.string :pdf_range_date_format

      t.timestamps
    end
  end
end
