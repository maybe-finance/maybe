class Import < ApplicationRecord
  belongs_to :account
  has_many :rows, dependent: :destroy
  validate :raw_csv_must_be_valid_csv, :column_mappings_must_contain_expected_fields
  validates_associated :rows

  enum :status, { pending: "pending", complete: "complete", importing: "importing", failed: "failed" }, validate: true

  store_accessor :column_mappings, :date, :merchant, :category, :amount

  scope :ordered, -> { order(:created_at) }
  scope :complete, -> { where(status: "complete") }
  scope :pending, -> { where(status: "pending") }

  def publish
    update!(status: "importing")
    import_rows
    update!(status: "complete")
  rescue => e
    update!(status: "failed")
    Rails.logger.error("Import with id #{id} failed: #{e}")
  end

  def publish_later
    ImportJob.perform_later(self)
  end

  def parsed_csv
    CSV.parse(raw_csv || "", headers: true, header_converters: :symbol, converters: [ ->(str) { str.strip } ])
  end

  def rows_mapped
    rows = []
    parsed_csv.map do |row|
      preview_row = {}
      required_keys.each { |key| preview_row[key] = row[column_mappings[key].to_sym] }
      rows << preview_row
    end
    rows
  end

  def rows_preview
    rows_mapped.first(3).map do |row|
      Import::Row.new \
        import: self,
        **row
    end
  end

  def default_column_mappings
    {
      "date" => parsed_csv.headers[0] || "date",
      "name" => parsed_csv.headers[1] || "name",
      "category" => parsed_csv.headers[2] || "category",
      "amount" => parsed_csv.headers[3] || "amount"
    }
  end

  private

    def import_rows
      rows.each do |row|
        family = self.account.family
        category = family.transaction_categories.find_or_create_by! name: row.category
        account.transactions.create! \
          name: row.name,
          date: Date.parse(row.date),
          category: category,
          amount: BigDecimal(row.amount),
          currency: account.currency
      end
    end

    def required_keys
      %w[date name category amount]
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
