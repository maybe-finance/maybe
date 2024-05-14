class Import::Row
  include ActiveModel::Validations

  attr_reader :import, :date, :name, :category, :amount

  validate :date_must_be_iso_format
  validates :amount, numericality: true

  def initialize(import: nil, date: nil, name: "Imported transaction", category: nil, amount: nil)
    @import = import
    @date = date
    @name = name
    @category = category
    @amount = amount
  end

  def fields
    [ date, name, category, amount ]
  end

  private

    def date_must_be_iso_format
      Date.iso8601(date)
    rescue ArgumentError
      errors.add(:date, "must be a valid ISO 8601 date")
    end
end
