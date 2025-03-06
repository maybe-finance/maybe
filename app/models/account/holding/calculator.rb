class Account::Holding::Calculator
  def initialize(account)
    @account = account
    @securities_cache = {}
  end

  def calculate
    raise NotImplementedError, "Subclasses must implement this method"
  end

  private
    attr_reader :account, :securities_cache
end
