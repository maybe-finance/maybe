# All Plaid data is fetched at the item-level.  This class is a simple wrapper that
# providers a convenience method, get_account_data which scopes the item-level payload
# to each Plaid Account
class PlaidItem::AccountsSnapshot
  def initialize(plaid_item, plaid_provider:)
    @plaid_item = plaid_item
    @plaid_provider = plaid_provider
  end

  def accounts
    @accounts ||= plaid_provider.get_item_accounts(plaid_item.access_token).accounts
  end

  def get_account_data(account_id)
    AccountData.new(
      account_data: accounts.find { |a| a.account_id == account_id },
      transactions_data: account_scoped_transactions_data(account_id),
      investments_data: account_scoped_investments_data(account_id),
      liabilities_data: account_scoped_liabilities_data(account_id)
    )
  end

  def transactions_cursor
    return nil unless transactions_data
    transactions_data.cursor
  end

  private
    attr_reader :plaid_item, :plaid_provider

    TransactionsData = Data.define(:added, :modified, :removed)
    LiabilitiesData = Data.define(:credit, :mortgage, :student)
    InvestmentsData = Data.define(:transactions, :holdings, :securities)
    AccountData = Data.define(:account_data, :transactions_data, :investments_data, :liabilities_data)

    def account_scoped_transactions_data(account_id)
      return nil unless transactions_data

      TransactionsData.new(
        added: transactions_data.added.select { |t| t.account_id == account_id },
        modified: transactions_data.modified.select { |t| t.account_id == account_id },
        removed: transactions_data.removed.select { |t| t.account_id == account_id }
      )
    end

    def account_scoped_investments_data(account_id)
      return nil unless investments_data

      transactions = investments_data.transactions.select { |t| t.account_id == account_id }
      holdings = investments_data.holdings.select { |h| h.account_id == account_id }
      securities = transactions.count > 0 && holdings.count > 0 ? investments_data.securities : []

      InvestmentsData.new(
        transactions: transactions,
        holdings: holdings,
        securities: securities
      )
    end

    def account_scoped_liabilities_data(account_id)
      return nil unless liabilities_data

      LiabilitiesData.new(
        credit: liabilities_data.credit&.find { |c| c.account_id == account_id },
        mortgage: liabilities_data.mortgage&.find { |m| m.account_id == account_id },
        student: liabilities_data.student&.find { |s| s.account_id == account_id }
      )
    end

    def can_fetch_transactions?
      plaid_item.supports_product?("transactions") && accounts.any?
    end

    def transactions_data
      return nil unless can_fetch_transactions?

      @transactions_data ||= plaid_provider.get_transactions(
        plaid_item.access_token,
        next_cursor: plaid_item.next_cursor
      )
    end

    def can_fetch_investments?
      plaid_item.supports_product?("investments") &&
      accounts.any? { |a| a.type == "investment" }
    end

    def investments_data
      return nil unless can_fetch_investments?
      @investments_data ||= plaid_provider.get_item_investments(plaid_item.access_token)
    end

    def can_fetch_liabilities?
      plaid_item.supports_product?("liabilities") &&
      accounts.any? do |a|
        a.type == "credit" && a.subtype == "credit card" ||
        a.type == "loan" && (a.subtype == "mortgage" || a.subtype == "student")
      end
    end

    def liabilities_data
      return nil unless can_fetch_liabilities?
      @liabilities_data ||= plaid_provider.get_item_liabilities(plaid_item.access_token)
    end
end
