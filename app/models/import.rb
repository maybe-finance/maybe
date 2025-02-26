class Import < ApplicationRecord
  TYPES = %w[TransactionImport TradeImport AccountImport MintImport].freeze
  SIGNAGE_CONVENTIONS = %w[inflows_positive inflows_negative]

  NUMBER_FORMATS = {
    "1,234.56" => { separator: ".", delimiter: "," },  # US/UK/Asia
    "1.234,56" => { separator: ",", delimiter: "." },  # Most of Europe
    "1 234,56" => { separator: ",", delimiter: " " },  # French/Scandinavian
    "1,234"    => { separator: "",  delimiter: "," },  # Zero-decimal currencies like JPY
    "1234,48"    => { separator: ",", delimiter: "" }    # European format without thousands delimiter
  }.freeze

  belongs_to :family

  before_validation :set_default_number_format

  scope :ordered, -> { order(created_at: :desc) }

  enum :status, {
    pending: "pending",
    complete: "complete",
    importing: "importing",
    reverting: "reverting",
    revert_failed: "revert_failed",
    failed: "failed"
  }, validate: true, default: "pending"

  validates :type, inclusion: { in: TYPES }
  validates :col_sep, inclusion: { in: [ ",", ";" ] }
  validates :signage_convention, inclusion: { in: SIGNAGE_CONVENTIONS }
  validates :number_format, presence: true, inclusion: { in: NUMBER_FORMATS.keys }

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

  def revert_later
    raise "Import is not revertable" unless revertable?

    update! status: :reverting

    RevertImportJob.perform_later(self)
  end

  def revert
    Import.transaction do
      accounts.destroy_all
      entries.destroy_all
    end

    family.sync

    update! status: :pending
  rescue => error
    update! status: :revert_failed, error: error.message
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
        exchange_operating_mic: row[exchange_operating_mic_col_label].to_s,
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

  def revertable?
    complete? || revert_failed?
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
      return "" if value.nil?

      format = NUMBER_FORMATS[number_format]
      return "" unless format

      # First, normalize spaces and remove any characters that aren't numbers, delimiters, separators, or minus signs
      sanitized = value.to_s.strip

      # Handle French/Scandinavian format specially
      if format[:delimiter] == " "
        sanitized = sanitized.gsub(/\s+/, "") # Remove all spaces first
      elsif format[:delimiter].blank? && format[:separator] == ","
        # Handle European format without thousands delimiter (like 13,48)
        sanitized = sanitized.gsub(/[^\d,\-]/, "")
      else
        sanitized = sanitized.gsub(/[^\d#{Regexp.escape(format[:delimiter])}#{Regexp.escape(format[:separator])}\-]/, "")

        # Replace delimiter with empty string
        if format[:delimiter].present?
          sanitized = sanitized.gsub(format[:delimiter], "")
        end
      end

      # Replace separator with period for proper float parsing
      if format[:separator].present?
        sanitized = sanitized.gsub(format[:separator], ".")
      end

      # Return empty string if not a valid number
      unless sanitized =~ /\A-?\d+\.?\d*\z/
        return ""
      end

      sanitized
    end

    def set_default_number_format
      self.number_format ||= "1,234.56" # Default to US/UK format
    end
end
