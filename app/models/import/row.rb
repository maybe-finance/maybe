class Import::Row < ApplicationRecord
  belongs_to :import

  store :fields, accessors: Import::FIELDS, coder: JSON

  validate :validate_required_fields, on: :update
  validate :date_is_iso_8601, on: :update
  validate :amount_is_bigdecimal, on: :update

  private

    def validate_required_fields
      validates_presence_of(Import::REQUIRED_FIELDS)
    end

    def date_is_iso_8601
      Date.iso8601(date)

      true
    rescue
      errors.add(:date, :invalid)
    end

    def amount_is_bigdecimal
      BigDecimal(amount)
      true
    rescue
      errors.add(:amount, :invalid)
    end
end
