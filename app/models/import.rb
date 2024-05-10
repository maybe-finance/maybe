class Import < ApplicationRecord
  belongs_to :account
  validate :raw_csv_must_be_valid_csv, :column_mappings_must_contain_expected_fields
  before_update :prevent_update_after_complete

  store_accessor :column_mappings, :date, :merchant, :category, :amount

  scope :ordered, -> { order(:created_at) }

  def complete?
    # Interim placeholder
    false
  end

  def confirm!
    puts "confirmed"
  end

  def preview_transactions
    rows = []
    parsed_csv.each do |row|
      preview_txn = Transaction.new \
        name: "imported transaction",
        date: row[:date],
        category: Transaction::Category.new(name: row[:category]),
        merchant: Transaction::Merchant.new(name: row[:merchant]),
        amount: row[:amount],
        account: account

      rows << preview_txn
    end

    rows
  end

  def parsed_csv
    CSV.parse(raw_csv || "", headers: true, header_converters: :symbol, converters: [ ->(str) { str.strip } ])
  end

  def update_cell!(row_idx:, col_idx:, value:)
    csv_copy = parsed_csv.by_col_or_row
    csv_copy[row_idx][col_idx] = value
    update! raw_csv: csv_copy.to_csv
  end

  def default_column_mappings
    {
      "date" => parsed_csv.headers[0] || "date",
      "merchant" => parsed_csv.headers[1] || "merchant",
      "category" => parsed_csv.headers[2] || "category",
      "amount" => parsed_csv.headers[3] || "amount"
    }
  end

  private

    def required_keys
      %w[date merchant category amount]
    end

    def column_mappings_must_contain_expected_fields
      return if column_mappings.nil?

      required_keys.each do |key|
        unless column_mappings.has_key?(key)
          errors.add(:column_mappings, "must contain the key #{key}")
        end

        expected_header = column_mappings[key] || ""
        unless parsed_csv.headers.include?(expected_header.to_sym)
          errors.add(:base, "column map has key #{key}, but could not find #{key} in raw csv input")
        end
      end
    end

    def prevent_update_after_complete
      if complete?
        errors.add(:base, "Update not allowed on a completed import.")
        throw(:abort)
      end
    end

    def raw_csv_must_be_valid_csv
      return if raw_csv.nil?

      if raw_csv.empty?
        errors.add(:raw_csv, "can't be empty")
        return
      end

      begin
        input_csv = CSV.parse(raw_csv, headers: true)

        if input_csv.headers.size < 4
          errors.add(:raw_csv, "must have at least 4 columns")
        end
      rescue CSV::MalformedCSVError
        errors.add(:raw_csv, "is not a valid CSV format")
      end
    end
end
