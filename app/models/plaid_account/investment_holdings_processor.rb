class PlaidAccount::InvestmentHoldingsProcessor
  include PlaidAccount::Securitizable

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    puts "processing investment holdings!"
  end

  private
    attr_reader :plaid_account

    def account
      plaid_account.account
    end
end
