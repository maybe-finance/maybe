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
  attribute :active_accounts_only, :boolean, default: true

  attr_reader :family

  def initialize(family, filters: {})
    @family = family
    super(filters)
  end

  def transactions_scope
    @transactions_scope ||= begin
      # This already joins entries + accounts. To avoid expensive double-joins, don't join them again (causes full table scan)
      query = family.transactions

      query = apply_active_accounts_filter(query, active_accounts_only)
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
  end

  # Computes totals for the specific search
  def totals
    @totals ||= begin
      Rails.cache.fetch("transaction_search_totals/#{cache_key_base}") do
        result = transactions_scope
                  .select(
                    "COALESCE(SUM(CASE WHEN entries.amount >= 0 THEN ABS(entries.amount * COALESCE(er.rate, 1)) ELSE 0 END), 0) as expense_total",
                    "COALESCE(SUM(CASE WHEN entries.amount < 0 THEN ABS(entries.amount * COALESCE(er.rate, 1)) ELSE 0 END), 0) as income_total",
                    "COUNT(entries.id) as transactions_count"
                  )
                  .joins(
                    ActiveRecord::Base.sanitize_sql_array([
                      "LEFT JOIN exchange_rates er ON (er.date = entries.date AND er.from_currency = entries.currency AND er.to_currency = ?)",
                      family.currency
                    ])
                  )
                  .take

        Totals.new(
          count: result.transactions_count.to_i,
          income_money: Money.new(result.income_total.to_i, family.currency),
          expense_money: Money.new(result.expense_total.to_i, family.currency)
        )
      end
    end
  end

  def cache_key_base
    [
      family.id,
      Digest::SHA256.hexdigest(attributes.sort.to_h.to_json), # cached by filters
      family.entries_cache_version
    ].join("/")
  end

  private
    Totals = Data.define(:count, :income_money, :expense_money)

    def apply_active_accounts_filter(query, active_accounts_only_filter)
      if active_accounts_only_filter
        query.where(accounts: { status: [ "draft", "active" ] })
      else
        query
      end
    end


    def apply_category_filter(query, categories)
      return query unless categories.present?

      query = query.left_joins(:category).where(
        "categories.name IN (?) OR (
        categories.id IS NULL AND (transactions.kind NOT IN ('funds_movement', 'cc_payment'))
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

      transfer_condition = "transactions.kind IN ('funds_movement', 'cc_payment', 'loan_payment')"
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
