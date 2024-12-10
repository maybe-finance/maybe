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
        # Plaid guarantees at least 1 of these
        balance: plaid_account_data.balances.current || plaid_account_data.balances.available,
        cash_balance: derive_plaid_cash_balance(plaid_account_data.balances)
      }
    )
  end

  def sync_investments!(transactions:, holdings:, securities:)
    transactions.each do |transaction|
      if transaction.type == "cash"
        new_transaction = account.entries.find_or_create_by!(plaid_id: transaction.investment_transaction_id) do |t|
          t.name = transaction.name
          t.amount = transaction.amount
          t.currency = transaction.iso_currency_code
          t.date = transaction.date
          t.marked_as_transfer = transaction.subtype.in?(%w[deposit withdrawal])
          t.entryable = Account::Transaction.new
        end
      else
        security = get_security(transaction.security, securities)
        next if security.nil?
        new_transaction = account.entries.find_or_create_by!(plaid_id: transaction.investment_transaction_id) do |t|
          t.name = transaction.name
          t.amount = transaction.quantity * transaction.price
          t.currency = transaction.iso_currency_code
          t.date = transaction.date
          t.entryable = Account::Trade.new(
            security: security,
            qty: transaction.quantity,
            price: transaction.price,
            currency: transaction.iso_currency_code
          )
        end
      end
    end

    # Update only the current day holdings.  The account sync will populate historical values based on trades.
    holdings.each do |holding|
      internal_security = get_security(holding.security, securities)
      next if internal_security.nil?

      existing_holding = account.holdings.find_or_initialize_by(
        security: internal_security,
        date: Date.current,
        currency: holding.iso_currency_code
      )

      existing_holding.qty = holding.quantity
      existing_holding.price = holding.institution_price
      existing_holding.amount = holding.quantity * holding.institution_price
      existing_holding.save!
    end
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

    modified.each do |plaid_txn|
      existing_txn = account.entries.find_by(plaid_id: plaid_txn.transaction_id)

      existing_txn.update!(
        amount: plaid_txn.amount,
        date: plaid_txn.date
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

    def get_security(plaid_security, securities)
      return nil if plaid_security.nil?

      security = if plaid_security.ticker_symbol.present?
        plaid_security
      else
        securities.find { |s| s.security_id == plaid_security.proxy_security_id }
      end

      return nil if security.nil? || security.ticker_symbol.blank?
      return nil if security.ticker_symbol == "CUR:USD" # Internally, we do not consider cash a "holding" and track it separately

      Security.find_or_create_by!(
        ticker: security.ticker_symbol,
        exchange_mic: security.market_identifier_code || "XNAS",
        country_code: "US"
      )
    end

    def transfer?(plaid_txn)
      transfer_categories = [ "TRANSFER_IN", "TRANSFER_OUT", "LOAN_PAYMENTS" ]

      transfer_categories.include?(plaid_txn.personal_finance_category.primary)
    end

    def create_initial_loan_balance(loan_data)
      if loan_data.origination_principal_amount.present? && loan_data.origination_date.present?
        account.entries.find_or_create_by!(plaid_id: loan_data.account_id) do |e|
          e.name = "Initial Principal"
          e.amount = loan_data.origination_principal_amount
          e.currency = account.currency
          e.date = loan_data.origination_date
          e.entryable = Account::Valuation.new
        end
      end
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

    def derive_plaid_cash_balance(plaid_balances)
      if account.investment?
        plaid_balances.available || 0
      else
        # For now, we will not distinguish between "cash" and "overall" balance for non-investment accounts
        plaid_balances.current || plaid_balances.available
      end
    end
end
