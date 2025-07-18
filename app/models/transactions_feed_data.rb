class TransactionsFeedData
  attr_reader :family

  def initialize(family, transactions)
    @family = family
    @transactions = transactions
  end

  private
    attr_reader :transactions
end
