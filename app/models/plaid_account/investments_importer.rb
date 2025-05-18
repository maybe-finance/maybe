class PlaidAccount::InvestmentsImporter
  def initialize(plaid_account, plaid_provider:)
    @plaid_account = plaid_account
    @plaid_provider = plaid_provider
  end

  def import
    # TODO
  end

  private
    attr_reader :plaid_account, :plaid_provider
end
