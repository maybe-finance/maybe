class Account::SeriesCalculator
  def initialize(account, holdings: nil)
    @account = account
    @holdings = holdings || []
  end

  def calculate
    raise NotImplementedError, "Subclasses must implement this method"
  end

  private
    attr_reader :account, :holdings
end
