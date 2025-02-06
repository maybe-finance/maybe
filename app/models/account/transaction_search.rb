class Account::TransactionSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :active, :boolean, default: false
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

  # Returns array of Account::Entry objects to stay consistent with partials, which only deal with Account::Entry
  def build_query(scope)
    query = scope.joins(entry: :account)

    if types.present? && types.exclude?("transfer")
      query = query.joins("LEFT JOIN transfers ON transfers.inflow_transaction_id = account_entries.id OR transfers.outflow_transaction_id = account_entries.id")
        .where("transfers.id IS NULL")
    end

    if categories.present?
      if categories.exclude?("Uncategorized")
        query = query
                  .joins(:category)
                  .where(categories: { name: categories })
      else
        query = query
                  .left_joins(:category)
                  .where(categories: { name: categories })
                  .or(query.where(category_id: nil))
      end
    end

    query = query.joins(:merchant).where(merchants: { name: merchants }) if merchants.present?

    query = query.joins(:tags).where(tags: { name: tags }) if tags.present?

    # Apply common entry search filters
    query = Account::EntrySearch.apply_active_filter(query, active)
    query = Account::EntrySearch.apply_search_filter(query, search)
    query = Account::EntrySearch.apply_date_filters(query, start_date, end_date)
    query = Account::EntrySearch.apply_type_filter(query, types)
    query = Account::EntrySearch.apply_amount_filter(query, amount, amount_operator)
    query = Account::EntrySearch.apply_accounts_filter(query, accounts, account_ids)

    query
  end
end
