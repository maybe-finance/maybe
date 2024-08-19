class Import::Csv
  DEFAULT_COL_SEP = ",".freeze
  COL_SEP_LIST = [ DEFAULT_COL_SEP, ";" ].freeze

  def self.parse_csv(csv_str, col_sep: DEFAULT_COL_SEP)
    CSV.parse(
      csv_str&.strip || "",
      headers: true,
      col_sep:,
      converters: [ ->(str) { str&.strip } ]
    )
  end

  def self.create_with_field_mappings(raw_file_str, fields, field_mappings, col_sep = DEFAULT_COL_SEP)
    raw_csv = self.parse_csv(raw_file_str, col_sep:)

    generated_csv_str = CSV.generate headers: fields.map { |f| f.key }, write_headers: true, col_sep: do |csv|
      raw_csv.each do |row|
        row_values = []

        fields.each do |field|
          # Finds the column header name the user has designated for the expected field
          mapped_field_key = field_mappings[field.key] if field_mappings
          mapped_header = mapped_field_key || field.key

          row_values << row.fetch(mapped_header, "")
        end

        csv << row_values
      end
    end

    new(generated_csv_str, col_sep:)
  end

  attr_reader :csv_str, :col_sep

  def initialize(csv_str, column_validators: nil, col_sep: DEFAULT_COL_SEP)
    @csv_str = csv_str
    @col_sep = col_sep
    @column_validators = column_validators || {}
  end

  def table
    @table ||= self.class.parse_csv(csv_str, col_sep:)
  end

  def update_cell(row_idx, col_idx, value)
    copy = table.by_col_or_row
    copy[row_idx][col_idx] = value
    copy
  end

  def valid?
    table.each_with_index.all? do |row, row_idx|
      row.each_with_index.all? do |cell, col_idx|
        cell_valid?(row_idx, col_idx)
      end
    end
  end

  def cell_valid?(row_idx, col_idx)
    value = table.dig(row_idx, col_idx)
    header = table.headers[col_idx]
    validator = get_validator_by_header(header)
    validator.call(value)
  end

  def define_validator(header_key, validator = nil, &block)
    header = table.headers.find { |h| h.strip == header_key }
    raise "Cannot define validator for header #{header_key}: header does not exist in CSV" if header.nil?

    column_validators[header] = validator || block
  end

  private

    attr_accessor :column_validators

    def get_validator_by_header(header)
      column_validators&.dig(header) || ->(_v) { true }
    end
end
