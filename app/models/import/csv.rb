class Import::Csv
  DEFAULT_COL_SEP = ",".freeze
  COL_SEP_LIST = [ DEFAULT_COL_SEP, ";" ].freeze

  def self.parse_csv(csv_str, headers: true, col_sep: DEFAULT_COL_SEP)
    CSV.parse(
      csv_str&.strip || "",
      headers: headers,
      col_sep:,
      converters: [ ->(str) { str&.strip } ]
    )
  end

  def self.available_fields(csv_str, col_sep: DEFAULT_COL_SEP)
    CSV.parse(csv_str, headers: false, col_sep:).first
  end

  def self.normalize(csv_str, field_mappings, col_sep)
    raw_csv = self.parse_csv(csv_str, col_sep: col_sep)

    rows = raw_csv.map do |row|
      row_values = {}

      Import::FIELDS.each do |field|
        # Finds the column header name the user has designated for the expected field
        mapped_field_key = field_mappings[field.to_s] if field_mappings
        mapped_header = mapped_field_key || field.to_s

        row_values[field] = row.fetch(mapped_header, "")
      end

      row_values
    end

    # reject empty rows
    rows.reject { |row| row.all? { |column| column.empty? } }
  end
end
