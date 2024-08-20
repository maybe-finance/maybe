class Import::RawPdf
  attr_accessor :import

  def initialize(import)
    @import = import
  end

  def available_fields
    transation_line_regex.named_captures.keys
  end

  def parse_raw
    return unless import.raw_file_str.present?

    PDF::Reader.new(StringIO.new(import.raw_file_str))
  end

  def generate_normalized_csv
    Import::Csv.create_from(transactions_rows, import.expected_fields, import.column_mappings)
  end

  private

    # PDF parsing
    def lines
      reader = PDF::Reader.new(StringIO.new(import.raw_file_str))
      reader.pages.flat_map { |page| page.text.split("\n") }
    end

    def transation_line_regex
      @transation_line_regex ||= Regexp.new(import.pdf_regex.transaction_line_regex_str)
    end

    def transactions_lines
      lines.map { |line| transation_line_regex.match?(line) ? line : nil }.compact_blank
    end

    def transform_row(line)
      row = transation_line_regex.match(line).named_captures
      row["date"] = iso_dates[row["date"]] if iso_dates[row["date"]]
      row["amount"] = row["amount"].to_s.gsub(".", "").gsub(",", ".") if /\A(\d+(.)?)*\d?\d?\d,(\d?\d)\z/.match(row["amount"].to_s.gsub("\s", ""))
      row["currency_code"] = metadata["currency_code"] if metadata["currency_code"].present?

      row
    end

    def transactions_rows
      transactions_lines.map { |line| transform_row(line) }
    end

    def metadata
      return @metadata unless defined?(:@metadata)

      return @metadata = {} if import.pdf_regex.metadata_regex_str.nil?

      @metadata = Regexp.new(
        import.pdf_regex.metadata_regex_str,
        Regexp::MULTILINE
      ).match(lines.join("\n"))&.named_captures
    end

    def iso_dates
      return @iso_dates unless defined?(:@iso_dates)

      @iso_dates = date_range.map { |date|
        [
          date.strftime(import.pdf_regex.pdf_transaction_date_format),
          date.iso8601
        ]
      }.to_h.presence
    end

    def date_range
      return [] if metadata["start_date"].nil?
      return [] if metadata["end_date"].nil?

      Date.parse(metadata["start_date"])..Date.parse(metadata["end_date"])
    end
end
