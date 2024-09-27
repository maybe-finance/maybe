class Import < ApplicationRecord
  TYPES = %w[TransactionImport TradeImport AccountImport MintImport].freeze

  belongs_to :family

  scope :ordered, -> { order(created_at: :desc) }

  enum :status, { pending: "pending", complete: "complete", importing: "importing", failed: "failed" }, validate: true

  validates :type, inclusion: { in: TYPES }
  validates :col_sep, inclusion: { in: [ ",", ";" ] }

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

  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        account: row[account_col_label] || default_empty_key,
        date: row[date_col_label],
        qty: row[qty_col_label],
        ticker: row[ticker_col_label],
        price: row[price_col_label],
        amount: row[amount_col_label],
        currency: row[currency_col_label] || default_currency,
        name: row[name_col_label] || default_row_name,
        category: row[category_col_label] || default_empty_key,
        tags: row[tags_col_label] || default_empty_key,
        entity_type: row[entity_type_col_label],
        notes: row[notes_col_label]
      }
    end

    inserted_rows = rows.insert_all!(mapped_rows)
  end

  def sync_mappings
    mapping_steps.each do |step|
      step.sync_rows(self.rows)
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

    def default_empty_key
      Import::Row::EMPTY_KEY
    end

    def normalize_date_str(date_str)
      Date.strptime(date_str, date_format).iso8601
    end

    def parsed_csv
      @parsed_csv ||= CSV.parse(
        (raw_file_str || "").strip,
        headers: true,
        col_sep: col_sep,
        converters: [ ->(str) { str&.strip } ]
      )
    end
end
