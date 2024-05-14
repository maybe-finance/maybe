class Import::Row
  include ActiveModel::Validations

  attr_reader :import, :date, :name, :category, :amount

  validates :date, format: /\A\d{4}-\d{2}-\d{2}\z/
  validates :amount, numericality: true

  def initialize(import: nil, date: nil, name: "Imported transaction", category: nil, amount: nil)
    @import = import
    @date = date
    @name = name
    @category = category
    @amount = amount
  end
end
