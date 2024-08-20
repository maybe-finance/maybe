class Import::RawCsv
  attr_accessor :import

  def initialize(import)
    @import = import
  end

  def available_fields
    get_raw_csv.table.headers
  end

  def parse_raw
    CSV.parse(import.raw_file_str || "", col_sep: import.col_sep)
  end

  # Uses the user-provided raw CSV + mappings to generate a normalized CSV for the import
  def generate_normalized_csv
    Import::Csv.create_with_field_mappings(import.raw_file_str, import.expected_fields, import.column_mappings, import.col_sep)
 end

  private

    def get_raw_csv
      return nil if import.raw_file_str.nil?

      Import::Csv.new(import.raw_file_str, col_sep: import.col_sep)
    end
end
