class PlaidAccount::Processor
  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def process
    PlaidAccount.transaction do
      account = family.accounts.find_or_initialize_by(
        plaid_account_id: plaid_account.id
      )

      account.set_name(plaid_account.name)
    end
  end

  private 
    def family
      plaid_account.plaid_item.family
    end
end