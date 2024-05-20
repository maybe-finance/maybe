class Import < ApplicationRecord
  belongs_to :account

  validate :raw_csv_must_be_parsable

  before_save :initialize_csv, if: :should_initialize_csv?

  enum :status, { pending: "pending", complete: "complete", importing: "importing", failed: "failed" }, validate: true

  store_accessor :column_mappings, :define_column_mapping_keys

  scope :ordered, -> { order(created_at: :desc) }

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
    get_normalized_csv_with_validation
  end

  def available_headers
    get_raw_csv.table.headers
  end

  def get_selected_header_for_field(field)
    column_mappings&.dig(field) || field.key
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

    def get_normalized_csv_with_validation
      return nil if normalized_csv_str.nil?

      csv = Import::Csv.new(normalized_csv_str)

      expected_fields.each do |field|
        csv.define_validator(field.key, field.validator) if field.validator
      end

      csv
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
          name: row["name"] || "Imported transaction",
          date: Date.iso8601(row["date"]),
          category: category,
          amount: BigDecimal(row["amount"]) * -1, # User inputs amounts with opposite signage of our internal representation
          currency: account.currency

        transactions << txn
      end

      transactions
    end

    def create_expected_fields
      date_field = Import::Field.new \
        key: "date",
        label: "Date",
        validator: ->(value) { Import::Field.iso_date_validator(value) }

      name_field = Import::Field.new \
        key: "name",
        label: "Name"

      category_field = Import::Field.new \
        key: "category",
        label: "Category"

      amount_field = Import::Field.new \
        key: "amount",
        label: "Amount",
        validator: ->(value) { Import::Field.bigdecimal_validator(value) }

      [ date_field, name_field, category_field, amount_field ]
    end

    def define_column_mapping_keys
      expected_fields.each do |field|
        field.key.to_sym
      end
    end

    def raw_csv_must_be_parsable
      begin
        CSV.parse(raw_csv_str || "")
      rescue CSV::MalformedCSVError
        errors.add(:raw_csv_str, "is not a valid CSV format")
      end
    end
end
