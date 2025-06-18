class Transaction::Search
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

    query = apply_category_filter(query, categories)
    query = apply_type_filter(query, types)
    query = apply_merchant_filter(query, merchants)
    query = apply_tag_filter(query, tags)
    query = EntrySearch.apply_search_filter(query, search)
    query = EntrySearch.apply_date_filters(query, start_date, end_date)
    query = EntrySearch.apply_amount_filter(query, amount, amount_operator)
    query = EntrySearch.apply_accounts_filter(query, accounts, account_ids)

    query
  end

  private
    def apply_category_filter(query, categories)
      return query unless categories.present?

      query = query.left_joins(:category).where(
        "categories.name IN (?) OR (
        categories.id IS NULL AND (transactions.kind NOT IN ('transfer', 'payment', 'one_time') OR transactions.kind = 'loan_payment')
      )",
        categories
      )

      if categories.exclude?("Uncategorized")
        query = query.where.not(category_id: nil)
      end

      query
    end

    def apply_type_filter(query, types)
      return query unless types.present?
      return query if types.sort == [ "expense", "income", "transfer" ]

      transfer_condition = "transactions.kind IN ('transfer', 'payment', 'one_time')"
      expense_condition = "entries.amount >= 0"
      income_condition = "entries.amount <= 0"

      condition = case types.sort
      when [ "transfer" ]
        transfer_condition
      when [ "expense" ]
        Arel.sql("(#{expense_condition} AND transactions.kind NOT IN ('transfer', 'payment', 'one_time')) OR transactions.kind = 'loan_payment'")
      when [ "income" ]
        Arel.sql("#{income_condition} AND transactions.kind NOT IN ('transfer', 'payment', 'one_time', 'loan_payment')")
      when [ "expense", "transfer" ]
        Arel.sql("(#{expense_condition} AND transactions.kind NOT IN ('transfer', 'payment', 'one_time')) OR transactions.kind = 'loan_payment' OR #{transfer_condition}")
      when [ "income", "transfer" ]
        Arel.sql("(#{income_condition} AND transactions.kind NOT IN ('transfer', 'payment', 'one_time', 'loan_payment')) OR #{transfer_condition}")
      when [ "expense", "income" ]
        Arel.sql("transactions.kind NOT IN ('transfer', 'payment', 'one_time') OR transactions.kind = 'loan_payment'")
      end

      query.where(condition)
    end

    def apply_merchant_filter(query, merchants)
      return query unless merchants.present?
      query.joins(:merchant).where(merchants: { name: merchants })
    end

    def apply_tag_filter(query, tags)
      return query unless tags.present?
      query.joins(:tags).where(tags: { name: tags })
    end
end
