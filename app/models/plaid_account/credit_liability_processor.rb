class PlaidAccount::CreditLiabilityProcessor
  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    puts "processing credit liability!"
  end

  private
    attr_reader :plaid_account

    def account
      plaid_account.account
    end
end
