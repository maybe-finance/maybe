class Import < ApplicationRecord
  FIELDS = [ :date, :name, :category, :tags, :amount ].freeze
  REQUIRED_FIELDS =  [ :date, :amount ].freeze

  belongs_to :account
  has_many :rows, dependent: :destroy, class_name: "Import::Row"

  accepts_nested_attributes_for :rows

  validate :raw_file_must_be_parsable
  validates :col_sep, inclusion: { in: Csv::COL_SEP_LIST }

  before_save :recreate_rows, if: :should_recreate_rows?

  enum :status, { pending: "pending", complete: "complete", importing: "importing", failed: "failed" }, validate: true

  store :column_mappings, accessors: FIELDS, suffix: :column_mapping

  scope :ordered, -> { order(created_at: :desc) }

  FALLBACK_TRANSACTION_NAME = "Imported transaction"

  def publish_later
    ImportJob.perform_later(self)
  end

  def loaded?
    raw_file_str.present?
  end

  def configured?
    rows.present?
  end

  def cleaned?
    loaded? && configured? && valid_rows?
  end

  def valid_rows?
    rows.all? { |row| row.valid? }
  end

  def available_fields
    Import::Csv.available_fields(raw_file_str, col_sep:)
  end

  # Type-specific methods (potential STI inheritance in future when more import types added)
  def publish
    update!(status: "importing")

    transaction do
      generate_transactions.each do |txn|
        txn.save!
      end
    end

    self.account.sync

    update!(status: "complete")
  rescue => e
    update!(status: "failed")
    Rails.logger.error("Import with id #{id} failed: #{e}")
  end

  def dry_run
    generate_transactions
  end

  private

    def should_recreate_rows?
      raw_file_str_changed? || column_mappings_changed?
    end

    def recreate_rows
      rows.destroy_all
      self.rows_attributes = Import::Csv.normalize(raw_file_str, column_mappings, col_sep).map.with_index do |a, index|
        { fields: a.as_json.to_h, index: index }
      end
    end

    def generate_transactions
      transaction_entries = []
      category_cache = {}
      tag_cache = {}

      rows.each do |row|
        category_name = row.fields["category"].presence
        tag_strings = row.fields["tags"].presence&.split("|") || []
        tags = []

        tag_strings.each do |tag_string|
          tags << tag_cache[tag_string] ||= account.family.tags.find_or_initialize_by(name: tag_string)
        end

        category = category_cache[category_name] ||= account.family.categories.find_or_initialize_by(name: category_name) if category_name.present?

        entry = account.entries.build \
          name: row.fields["name"].presence || FALLBACK_TRANSACTION_NAME,
          date: Date.iso8601(row.fields["date"]),
          currency: account.currency,
          amount: BigDecimal(row.fields["amount"]) * -1,
          entryable: Account::Transaction.new(category: category, tags: tags)

        transaction_entries << entry
      end

      transaction_entries
    end

    def raw_file_must_be_parsable
      begin
        CSV.parse(raw_file_str || "", col_sep:)
      rescue CSV::MalformedCSVError
        errors.add(:raw_file_str, :invalid_csv_format)
      end
    end
end
