# PlaidItem::Importer passes a raw payload retrieved from accounts_get API call, along with the PlaidAccount entity
# This class is responsible for making sense of that raw data, persisting it, and triggering transaction/investment/liability data imports for this account
class PlaidAccount::Importer
  def initialize(plaid_account, account_data:, transactions_data:, investments_data:, liabilities_data:)
    @plaid_account = plaid_account
    @account_data = account_data
    @transactions_data = transactions_data
    @investments_data = investments_data
    @liabilities_data = liabilities_data
  end

  def import
    update_account_info

    import_transactions if transactions_data.present?
    import_investments if investments_data.present?
    import_liabilities if liabilities_data.present?
  end

  private
    attr_reader :plaid_account, :account_data, :transactions_data, :investments_data, :liabilities_data

    def update_account_info
      plaid_account.raw_payload = account_data
      plaid_account.current_balance = account_data.balances.current
      plaid_account.available_balance = account_data.balances.available
      plaid_account.currency = account_data.balances.iso_currency_code
      plaid_account.plaid_type = account_data.type
      plaid_account.plaid_subtype = account_data.subtype
      plaid_account.name = account_data.name
      plaid_account.mask = account_data.mask

      plaid_account.save!
    end

    def import_transactions
      PlaidAccount::TransactionsImporter.new(plaid_account, transactions_data: transactions_data).import
    end

    def import_investments
      PlaidAccount::InvestmentsImporter.new(plaid_account, investments_data: investments_data).import
    end

    def import_liabilities
      PlaidAccount::LiabilitiesImporter.new(plaid_account, liabilities_data: liabilities_data).import
    end
end
