class PlaidAccount < ApplicationRecord
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
          balance: plaid_data.balances.current || plaid_data.balances.available,
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
        # Plaid guarantees at least 1 of these
        balance: plaid_account_data.balances.current || plaid_account_data.balances.available,
        cash_balance: derive_plaid_cash_balance(plaid_account_data.balances)
      }
    )
  end

  def sync_investments!(transactions:, holdings:, securities:)
    PlaidInvestmentSync.new(self).sync!(transactions:, holdings:, securities:)
  end

  def sync_credit_data!(plaid_credit_data)
    account.update!(
      accountable_attributes: {
        id: account.accountable_id,
        minimum_payment: plaid_credit_data.minimum_payment_amount,
        apr: plaid_credit_data.aprs.first&.apr_percentage
      }
    )
  end

  def sync_mortgage_data!(plaid_mortgage_data)
    create_initial_loan_balance(plaid_mortgage_data)

    account.update!(
      accountable_attributes: {
        id: account.accountable_id,
        rate_type: plaid_mortgage_data.interest_rate&.type,
        interest_rate: plaid_mortgage_data.interest_rate&.percentage
      }
    )
  end

  def sync_student_loan_data!(plaid_student_loan_data)
    create_initial_loan_balance(plaid_student_loan_data)

    account.update!(
      accountable_attributes: {
        id: account.accountable_id,
        rate_type: "fixed",
        interest_rate: plaid_student_loan_data.interest_rate_percentage
      }
    )
  end

  def sync_transactions!(added:, modified:, removed:)
    added.each do |plaid_txn|
      account.entries.find_or_create_by!(plaid_id: plaid_txn.transaction_id) do |t|
        t.name = plaid_txn.merchant_name || plaid_txn.original_description
        t.amount = plaid_txn.amount
        t.currency = plaid_txn.iso_currency_code
        t.date = plaid_txn.date
        t.entryable = Transaction.new(
          plaid_category: plaid_txn.personal_finance_category.primary,
          plaid_category_detailed: plaid_txn.personal_finance_category.detailed,
          merchant: find_or_create_merchant(plaid_txn)
        )
      end
    end

    modified.each do |plaid_txn|
      existing_txn = account.entries.find_by(plaid_id: plaid_txn.transaction_id)

      existing_txn.update!(
        amount: plaid_txn.amount,
        date: plaid_txn.date,
        entryable_attributes: {
          plaid_category: plaid_txn.personal_finance_category.primary,
          plaid_category_detailed: plaid_txn.personal_finance_category.detailed,
          merchant: find_or_create_merchant(plaid_txn)
        }
      )
    end

    removed.each do |plaid_txn|
      account.entries.find_by(plaid_id: plaid_txn.transaction_id)&.destroy
    end
  end

  private
    def family
      plaid_item.family
    end

    def create_initial_loan_balance(loan_data)
      if loan_data.origination_principal_amount.present? && loan_data.origination_date.present?
        account.entries.find_or_create_by!(plaid_id: loan_data.account_id) do |e|
          e.name = "Initial Principal"
          e.amount = loan_data.origination_principal_amount
          e.currency = account.currency
          e.date = loan_data.origination_date
          e.entryable = Valuation.new
        end
      end
    end

    def find_or_create_merchant(plaid_txn)
      unless plaid_txn.merchant_entity_id.present? && plaid_txn.merchant_name.present?
        return nil
      end

      ProviderMerchant.find_or_create_by!(
        source: "plaid",
        name: plaid_txn.merchant_name,
      ) do |m|
        m.provider_merchant_id = plaid_txn.merchant_entity_id
        m.website_url = plaid_txn.website
        m.logo_url = plaid_txn.logo_url
      end
    end

    def derive_plaid_cash_balance(plaid_balances)
      if account.investment?
        plaid_balances.available || 0
      else
        # For now, we will not distinguish between "cash" and "overall" balance for non-investment accounts
        plaid_balances.current || plaid_balances.available
      end
    end
end
