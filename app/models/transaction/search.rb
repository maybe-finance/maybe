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
                 .joins(transfer_join)

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
    def transfer_join
      <<~SQL
        LEFT JOIN (
          SELECT t.*, t.id as transfer_id, a.accountable_type
          FROM transfers t
          JOIN entries ae ON ae.entryable_id = t.inflow_transaction_id
          AND ae.entryable_type = 'Transaction'
        JOIN accounts a ON a.id = ae.account_id
        ) transfer_info ON (
          transfer_info.inflow_transaction_id = transactions.id OR
            transfer_info.outflow_transaction_id = transactions.id
        )
      SQL
    end

    def apply_category_filter(query, categories)
      return query unless categories.present?

      query = query.left_joins(:category).where(
        "categories.name IN (?) OR (
        categories.id IS NULL AND (transfer_info.transfer_id IS NULL OR transfer_info.accountable_type = 'Loan')
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

      transfer_condition = "transfer_info.transfer_id IS NOT NULL"
      expense_condition = "entries.amount >= 0"
      income_condition = "entries.amount <= 0"

      condition = case types.sort
      when [ "transfer" ]
        transfer_condition
      when [ "expense" ]
        Arel.sql("#{expense_condition} AND NOT (#{transfer_condition})")
      when [ "income" ]
        Arel.sql("#{income_condition} AND NOT (#{transfer_condition})")
      when [ "expense", "transfer" ]
        Arel.sql("#{expense_condition} OR #{transfer_condition}")
      when [ "income", "transfer" ]
        Arel.sql("#{income_condition} OR #{transfer_condition}")
      when [ "expense", "income" ]
        Arel.sql("NOT (#{transfer_condition})")
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
