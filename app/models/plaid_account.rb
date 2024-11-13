class PlaidAccount < ApplicationRecord
  include Plaidable

  TYPE_MAPPING = {
    "depository" => Depository,
    "credit" => CreditCard,
    "loan" => Loan,
    "investment" => Investment,
    "other" => OtherAsset
  }

  belongs_to :plaid_item

  has_one :account, dependent: :destroy

  accepts_nested_attributes_for :account

  class << self
    def find_or_create_from_plaid_data!(plaid_data, family)
      find_or_create_by!(plaid_id: plaid_data.account_id) do |a|
        a.account = family.accounts.new(
          name: plaid_data.name,
          balance: plaid_data.balances.current,
          currency: plaid_data.balances.iso_currency_code,
          accountable: TYPE_MAPPING[plaid_data.type].new
        )
      end
    end
  end

  def sync_account_data!(plaid_account_data)
    update!(
      current_balance: plaid_account_data.balances.current,
      available_balance: plaid_account_data.balances.available,
      currency: plaid_account_data.balances.iso_currency_code,
      plaid_type: plaid_account_data.type,
      plaid_subtype: plaid_account_data.subtype,
      account_attributes: {
        id: account.id,
        balance: plaid_account_data.balances.current
      }
    )
  end

  def sync_transactions!(plaid_transactions_data)
    plaid_transactions_data.added.each do |plaid_txn|
      account.entries.account_transactions.find_or_create_by!(plaid_id: plaid_txn.transaction_id) do |t|
        t.name = plaid_txn.name
        t.amount = plaid_txn.amount
        t.currency = plaid_txn.iso_currency_code
        t.date = plaid_txn.date
        t.marked_as_transfer = transfer?(plaid_txn)
        t.entryable = Account::Transaction.new(
          category: get_category(plaid_txn.personal_finance_category.primary),
          merchant: get_merchant(plaid_txn.merchant_name)
        )
      end
    end

    plaid_transactions_data.modified.each do |plaid_txn|
      existing_txn = account.entries.account_transactions.find_by(plaid_id: plaid_txn.transaction_id)

      existing_txn.update!(
        amount: plaid_txn.amount,
        date: plaid_txn.date
      )
    end

    plaid_transactions_data.removed.each do |plaid_txn|
      account.entries.account_transactions.find_by(plaid_id: plaid_txn.transaction_id)&.destroy
    end
  end

  private
    def family
      plaid_item.family
    end

    def transfer?(plaid_txn)
      transfer_categories = [ "TRANSFER_IN", "TRANSFER_OUT", "LOAN_PAYMENTS" ]

      transfer_categories.include?(plaid_txn.personal_finance_category.primary)
    end

    # See https://plaid.com/documents/transactions-personal-finance-category-taxonomy.csv
    def get_category(plaid_category)
      ignored_categories = [ "BANK_FEES", "TRANSFER_IN", "TRANSFER_OUT", "LOAN_PAYMENTS", "OTHER" ]

      return nil if ignored_categories.include?(plaid_category)

      family.categories.find_or_create_by!(name: plaid_category.titleize)
    end

    def get_merchant(plaid_merchant_name)
      return nil if plaid_merchant_name.blank?

      family.merchants.find_or_create_by!(name: plaid_merchant_name)
    end
end
