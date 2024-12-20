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

  # Returns array of Account::Entry objects to stay consistent with partials, which only deal with Account::Entry
  def build_query(scope)
    query = scope

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

    entries_scope = Account::Entry.account_transactions.where(entryable_id: query.select(:id))

    Account::EntrySearch.from_entryable_search(self).build_query(entries_scope)
  end
end
