class SimpleFinAccount < ApplicationRecord
  TYPE_MAPPING = {
    "Depository" => Depository,
    "CreditCard" => CreditCard,
    "Loan" => Loan,
    "Investment" => Investment,
    "Other" => OtherAsset
  }

  belongs_to :simple_fin_connection
  has_one :account, dependent: :destroy, foreign_key: :simple_fin_account_id, inverse_of: :simple_fin_account

  accepts_nested_attributes_for :account

  validates :external_id, presence: true, uniqueness: true
  validates :simple_fin_connection_id, presence: true

  class << self
    def find_or_create_from_simple_fin_data!(sf_account_data, sfc)
      sfc.simple_fin_accounts.find_or_create_by!(external_id: sf_account_data["id"]) do |sfa|
        sfa.account = sfc.family.accounts.new(
          name: sf_account_data["name"],
          balance: sf_account_data["balance"].to_d,
          currency: sf_account_data["currency"],
          accountable: TYPE_MAPPING[sf_account_data["type"]].new,
          subtype: sf_account_data["subtype"],
          simple_fin_account: sfa, # Explicitly associate back
          last_synced_at: Time.current # Mark as synced upon creation
        )
        # Populate other fields on sfa from sf_account_data if needed
        # sfa.current_balance = sf_account_data["balance"].to_d
        # sfa.available_balance = sf_account_data["available-balance"]&.to_d
        # sfa.currency = sf_account_data["currency"]
        # sfa.sf_type = accountable_type
        # sfa.sf_subtype = sf_account_data["name"]&.include?("Credit") ? "Credit Card" : accountable_klass.name
      end
    end
  end

  # sf_account_data is a hash from Provider::SimpleFin#get_available_accounts
  def sync_account_data!(sf_account_data)
    # Ensure accountable_attributes has the ID for updates
    accountable_attributes = { id: account.accountable_id }

    # Example: Update specific accountable types like PlaidAccount does
    # This will depend on the structure of sf_account_data and your Accountable models
    # case account.accountable_type
    # when "CreditCard"
    #   accountable_attributes.merge!(
    #     # minimum_payment: sf_account_data.dig("credit_details", "minimum_payment"),
    #     # apr: sf_account_data.dig("credit_details", "apr")
    #   )
    # when "Loan"
    #   accountable_attributes.merge!(
    #     # interest_rate: sf_account_data.dig("loan_details", "interest_rate")
    #   )
    # end

    update!(
      current_balance: sf_account_data["balance"].to_d,
      available_balance: sf_account_data["available-balance"]&.to_d,
      currency: sf_account_data["currency"],
      # sf_type: derive_sf_type(sf_account_data), # Potentially update type/subtype
      # sf_subtype: derive_sf_subtype(sf_account_data),
      simple_fin_errors: sf_account_data["errors"] || [], # Assuming errors might come on account data
      account_attributes: {
        id: account.id,
        balance: sf_account_data["balance"].to_d,
        # cash_balance: derive_sf_cash_balance(sf_account_data), # If applicable
        last_synced_at: Time.current,
        accountable_attributes: accountable_attributes
      }
    )
  end

  # TODO: Implement if SimpleFIN provides investment transactions/holdings
  # def sync_investments!(transactions:, holdings:, securities:)
  #   # Similar to PlaidInvestmentSync.new(self).sync!(...)
  # end

  # TODO: Implement if SimpleFIN provides transactions
  # def sync_transactions!(added:, modified:, removed:)
  #   # Similar to PlaidAccount's sync_transactions!
  # end

  def family
    simple_fin_connection&.family
  end

  private

  # Example helper, if needed
  # def derive_sf_cash_balance(sf_balances)
  #   if account.investment?
  #     sf_balances["available-balance"]&.to_d || 0
  #   else
  #     sf_balances["balance"]&.to_d
  #   end
  # end
end
