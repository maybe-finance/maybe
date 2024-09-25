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

  def csv_rows
    @csv_rows ||= parsed_csv
  end

  def csv_headers
    parsed_csv.headers
  end

  def csv_sample
    @csv_sample ||= parsed_csv.first(2)
  end

  def uploaded?
    raw_file_str.present?
  end

  def configured?
    raise NotImplementedError, "Subclass must implement configured?"
  end

  def cleaned?
    configured? && rows.all?(&:valid?)
  end

  def publishable?
    raise NotImplementedError, "Subclass must implement publishable?"
  end

  private
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
