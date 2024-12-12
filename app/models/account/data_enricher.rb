class Account::DataEnricher
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def run
    enrich_transactions
  end

  private
    def enrich_transactions
      account.entries.account_transactions.each(&:enrich)
    end
end
