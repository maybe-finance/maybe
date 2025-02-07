class Import < ApplicationRecord
  TYPES = %w[TransactionImport TradeImport AccountImport MintImport].freeze
  SIGNAGE_CONVENTIONS = %w[inflows_positive inflows_negative]
  NUMBER_FORMATS = {
    "1,234.56" => { separator: ".", delimiter: "," },  # US/UK/Asia
    "1.234,56" => { separator: ",", delimiter: "." },  # Most of Europe
    "1 234,56" => { separator: ",", delimiter: " " },  # French/Scandinavian
    "1,234"    => { separator: "",  delimiter: "," }   # Zero-decimal currencies like JPY
  }.freeze

  belongs_to :family

  scope :ordered, -> { order(created_at: :desc) }

  enum :status, { pending: "pending", complete: "complete", importing: "importing", failed: "failed" }, validate: true

  validates :type, inclusion: { in: TYPES }
  validates :col_sep, inclusion: { in: [ ",", ";" ] }
  validates :signage_convention, inclusion: { in: SIGNAGE_CONVENTIONS }
  validates :currency, presence: true
  validates :number_format, inclusion: { in: NUMBER_FORMATS.keys }

  has_many :rows, dependent: :destroy
  has_many :mappings, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :entries, dependent: :destroy, class_name: "Account::Entry"

  def publish_later
    raise "Import is not publishable" unless publishable?

    update! status: :importing

    ImportJob.perform_later(self)
  end

  def publish
    import!

    family.sync

    update! status: :complete
  rescue => error
    update! status: :failed, error: error.message
  end

  def csv_rows
    @csv_rows ||= parsed_csv
  end

  def csv_headers
    parsed_csv.headers
  end

  def csv_sample
    @csv_sample ||= parsed_csv.first(2)
  end

  def dry_run
    {
      transactions: rows.count,
      accounts: Import::AccountMapping.for_import(self).creational.count,
      categories: Import::CategoryMapping.for_import(self).creational.count,
      tags: Import::TagMapping.for_import(self).creational.count
    }
  end

  def required_column_keys
    []
  end

  def column_keys
    raise NotImplementedError, "Subclass must implement column_keys"
  end

  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        account: row[account_col_label].to_s,
        date: row[date_col_label].to_s,
        qty: sanitize_number(row[qty_col_label]).to_s,
        ticker: row[ticker_col_label].to_s,
        price: sanitize_number(row[price_col_label]).to_s,
        amount: sanitize_number(row[amount_col_label]).to_s,
        currency: (row[currency_col_label] || default_currency).to_s,
        name: (row[name_col_label] || default_row_name).to_s,
        category: row[category_col_label].to_s,
        tags: row[tags_col_label].to_s,
        entity_type: row[entity_type_col_label].to_s,
        notes: row[notes_col_label].to_s
      }
    end

    rows.insert_all!(mapped_rows)
  end

  def sync_mappings
    mapping_steps.each do |mapping|
      mapping.sync(self)
    end
  end

  def mapping_steps
    []
  end

  def uploaded?
    raw_file_str.present?
  end

  def configured?
    uploaded? && rows.any?
  end

  def cleaned?
    configured? && rows.all?(&:valid?)
  end

  def publishable?
    cleaned? && mappings.all?(&:valid?)
  end

  def has_unassigned_account?
    mappings.accounts.where(key: "").any?
  end

  def requires_account?
    family.accounts.empty? && has_unassigned_account?
  end

  private
    def import!
      # no-op, subclasses can implement for customization of algorithm
    end

    def default_row_name
      "Imported item"
    end

    def default_currency
      family.currency
    end

    def parsed_csv
      @parsed_csv ||= CSV.parse(
        (raw_file_str || "").strip,
        headers: true,
        col_sep: col_sep,
        converters: [ ->(str) { str&.strip } ]
      )
    end

    def sanitize_number(value)
      # Special case: nil or empty values remain empty strings
      return "" if value.nil? || value.to_s.strip.empty?

      format = NUMBER_FORMATS[number_format] || NUMBER_FORMATS["1,234.56"]
      value = value.to_s.strip

      # Remove any currency symbols or other non-numeric characters except the format's delimiter and separator
      allowed_chars = [ format[:delimiter], format[:separator], "-" ].compact
      sanitized = value.gsub(/[^#{Regexp.escape(allowed_chars.join)}0-9]/, "")

      # Return empty string if no digits present (non-numeric input)
      return "" unless sanitized.match?(/[0-9]/)

      # Convert to standard format (period as decimal separator, no thousands delimiter)
      if format[:separator].present?
        # Replace delimiter with nothing first, then replace separator with period
        sanitized = sanitized.gsub(format[:delimiter], "").gsub(format[:separator], ".")
      else
        # For zero-decimal currencies, just remove the delimiter
        sanitized = sanitized.gsub(format[:delimiter], "")
      end

      # Extract sign for later
      is_negative = sanitized.count("-") > 0
      sanitized = sanitized.delete("-")

      # Handle decimal points
      case sanitized.count(".")
      when 0
        # No decimal point, nothing to do
      when 1
        # Single decimal point - handle edge cases
        if sanitized == "."
          return ""  # Just a decimal point, treat as non-numeric
        end
        # Add leading/trailing zeros if needed
        sanitized = "0" + sanitized if sanitized.start_with?(".")
        sanitized += "0" if sanitized.end_with?(".")
      else
        # Multiple decimal points - take everything before first decimal and first decimal place only
        parts = sanitized.split(".")
        sanitized = parts[0] + "." + (parts[1] || "")
      end

      # Reapply negative sign if present
      sanitized = "-" + sanitized if is_negative

      # Final validation - should look like a valid number now
      return "" unless sanitized.match?(/\A-?\d+\.?\d*\z/)

      sanitized
    end
end
