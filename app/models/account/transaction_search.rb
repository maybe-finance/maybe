class Account::TransactionSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :search, :string
  attribute :amount, :string
  attribute :amount_operator, :string
  attribute :types, array: true
  attribute :accounts, array: true
  attribute :account_ids, array: true
  attribute :start_date, :string
  attribute :end_date, :string
  attribute :categories, array: true
  attribute :merchants, array: true
  attribute :tags, array: true

  def build_query(scope)
    query = scope.joins(entry: :account)
                 .joins(
                    "LEFT JOIN (
                      SELECT t.*, t.id as transfer_id, a.accountable_type
                      FROM transfers t
                      JOIN account_entries ae ON ae.entryable_id = t.inflow_transaction_id
                        AND ae.entryable_type = 'Account::Transaction'
                      JOIN accounts a ON a.id = ae.account_id
                    ) transfer_info ON (
                      transfer_info.inflow_transaction_id = account_transactions.id OR
                      transfer_info.outflow_transaction_id = account_transactions.id
                    )"
                  )

    if categories.present?
      # If uncategorized is selected, we only show "categorizable" transfers (loan payments) or regular incomes/expenses
      query = query.left_joins(:category).where(
        "categories.name IN (?) OR (
          categories.id IS NULL AND (transfer_info.transfer_id IS NULL OR transfer_info.accountable_type = 'Loan')
        )",
        categories
      )

      # If uncategorized is not selected, exclude transactions with nil category
      if categories.exclude?("Uncategorized")
        query = query.where.not(category_id: nil)
      end
    end

    query = query.joins(:merchant).where(merchants: { name: merchants }) if merchants.present?

    query = query.joins(:tags).where(tags: { name: tags }) if tags.present?

    # Apply common entry search filters
    query = Account::EntrySearch.apply_search_filter(query, search)
    query = Account::EntrySearch.apply_date_filters(query, start_date, end_date)
    query = Account::EntrySearch.apply_type_filter(query, types)
    query = Account::EntrySearch.apply_amount_filter(query, amount, amount_operator)
    query = Account::EntrySearch.apply_accounts_filter(query, accounts, account_ids)

    query
  end
end
