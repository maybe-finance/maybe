class Import < ApplicationRecord
  belongs_to :account
  has_many :rows, dependent: :destroy
  validate :raw_csv_must_be_valid_csv
  before_update :prevent_update_after_complete
  scope :ordered, -> { order(:created_at) }

  def complete?
    # Interim placeholder
    false
  end

  private

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
        CSV.parse(raw_csv)
      rescue CSV::MalformedCSVError
        errors.add(:raw_csv, "is not a valid CSV format")
      end
    end
end
