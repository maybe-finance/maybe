class PlaidAccount < ApplicationRecord
  belongs_to :plaid_item

  has_one :account, dependent: :destroy

  accepts_nested_attributes_for :account

  class << self
    def create_from_plaid_data!(plaid_data, family)
      create!(
        plaid_id: plaid_data.account_id,
        current_balance: plaid_data.balances.current,
        available_balance: plaid_data.balances.available,
        currency: plaid_data.balances.iso_currency_code,
        plaid_type: plaid_data.type,
        plaid_subtype: plaid_data.subtype,
        name: plaid_data.name,
        mask: plaid_data.mask,
        account: family.accounts.new(
          name: plaid_data.name,
          balance: plaid_data.balances.current,
          currency: plaid_data.balances.iso_currency_code,
          accountable: plaid_type_to_accountable(plaid_data.type)
        )
      )
    end

    def plaid_type_to_accountable(plaid_type)
      case plaid_type
      when "depository"
        Depository.new
      when "credit"
        CreditCard.new
      when "loan"
        Loan.new
      when "investment"
        Investment.new
      else
        OtherAsset.new
      end
    end
  end
end
