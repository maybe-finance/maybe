class Import < ApplicationRecord
  belongs_to :account

  validate :raw_csv_must_be_parsable

  before_save :initialize_csv, if: :should_initialize_csv?

  enum :status, { pending: "pending", complete: "complete", importing: "importing", failed: "failed" }, validate: true

  store_accessor :column_mappings, :date, :merchant, :category, :amount

  scope :ordered, -> { order(:created_at) }
  scope :complete, -> { where(status: "complete") }
  scope :pending, -> { where(status: "pending") }

  def publish_later
    ImportJob.perform_later(self)
  end

  def loaded?
    raw_csv_str.present?
  end

  def configured?
    csv.present?
  end

  def cleaned?
    loaded? && configured? && csv.valid?
  end

  def csv
    get_normalized_csv
  end

  def available_headers
    get_raw_csv.table.headers
  end

  def update_csv!(row_idx:, col_idx:, value:)
    updated_csv = csv.update_cell(row_idx.to_i, col_idx.to_i, value)
    update! normalized_csv_str: updated_csv.to_s
  end

  # Type-specific methods (potential STI inheritance in future when more import types added)
  def publish
    update!(status: "importing")

    transaction do
      generate_transactions.each do |txn|
        txn.save!
      end
    end

    update!(status: "complete")
  rescue => e
    update!(status: "failed")
    Rails.logger.error("Import with id #{id} failed: #{e}")
  end

  def dry_run
    generate_transactions
  end

  def expected_fields
    @expected_fields ||= create_expected_fields
  end

  private

    def get_normalized_csv
      return nil if normalized_csv_str.nil?
      generate_normalized_csv(normalized_csv_str)
    end

    def get_raw_csv
      return nil if raw_csv_str.nil?
      Import::Csv.new(raw_csv_str)
    end

    def should_initialize_csv?
      raw_csv_str_changed? || column_mappings_changed?
    end

    def initialize_csv
      generated_csv = generate_normalized_csv(raw_csv_str)
      self.normalized_csv_str = generated_csv.table.to_s
    end

    # Uses the user-provided raw CSV + mappings to generate a normalized CSV for the import
    def generate_normalized_csv(csv_str)
      Import::Csv.create_with_field_mappings(csv_str, expected_fields, column_mappings)
    end

    def update_csv(row_idx, col_idx, value)
      updated_csv = csv.update_cell(row_idx.to_i, col_idx.to_i, value)
      update! normalized_csv_str: updated_csv.to_s
    end

    def generate_transactions
      transactions = []

      csv.table.each do |row|
        category = account.family.transaction_categories.find_or_initialize_by(name: row["category"])
        txn = account.transactions.build \
          name: row["name"],
          date: Date.iso8601(row["date"]),
          category: category,
          amount: BigDecimal(row["amount"])

        transactions << txn
      end

      transactions
    end

    def create_expected_fields
      date_field = Import::Field.new \
        key: "date",
        label: "Date",
        validator: method(:iso_date_validator)

      name_field = Import::Field.new \
        key: "name",
        label: "Name"

      category_field = Import::Field.new \
        key: "category",
        label: "Category"

      amount_field = Import::Field.new \
        key: "amount",
        label: "Amount"

      [ date_field, name_field, category_field, amount_field ]
    end

    def iso_date_validator(value)
      Date.iso8601(value)
      true
    rescue
      false
    end

    def raw_csv_must_be_parsable
      begin
        CSV.parse(raw_csv_str || "")
      rescue CSV::MalformedCSVError
        errors.add(:raw_csv_str, "is not a valid CSV format")
      end
    end
end
