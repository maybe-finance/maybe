class Import::Row
  attr_reader :import, :date, :name, :category, :amount

  def initialize(import: nil, date: nil, name: "Imported transaction", category: nil, amount: nil)
    @import = import
    @date = date
    @name = name
    @category = category
    @amount = amount
  end
end
