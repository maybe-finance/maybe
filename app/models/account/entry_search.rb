class Account::EntrySearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :search, :string
  attribute :amount, :string
  attribute :amount_operator, :string
  attribute :types, :string
  attribute :accounts, array: true
  attribute :account_ids, array: true
  attribute :start_date, :string
  attribute :end_date, :string

  class << self
    def from_entryable_search(entryable_search)
      new(entryable_search.attributes.slice(*attribute_names))
    end
  end

  def build_query(scope)
    query = scope

    query = query.where("account_entries.name ILIKE :search OR account_entries.enriched_name ILIKE :search",
      search: "%#{ActiveRecord::Base.sanitize_sql_like(search)}%"
    ) if search.present?
    query = query.where("account_entries.date >= ?", start_date) if start_date.present?
    query = query.where("account_entries.date <= ?", end_date) if end_date.present?

    if types.present?
      query = query.where(marked_as_transfer: false) unless types.include?("transfer")

      if types.include?("income") && !types.include?("expense")
        query = query.where("account_entries.amount < 0")
      elsif types.include?("expense") && !types.include?("income")
        query = query.where("account_entries.amount >= 0")
      end
    end

    if amount.present? && amount_operator.present?
      case amount_operator
      when "equal"
        query = query.where("ABS(ABS(account_entries.amount) - ?) <= 0.01", amount.to_f.abs)
      when "less"
        query = query.where("ABS(account_entries.amount) < ?", amount.to_f.abs)
      when "greater"
        query = query.where("ABS(account_entries.amount) > ?", amount.to_f.abs)
      end
    end

    if accounts.present? || account_ids.present?
      query = query.joins(:account)
    end

    query = query.where(accounts: { name: accounts }) if accounts.present?
    query = query.where(accounts: { id: account_ids }) if account_ids.present?

    query
  end
end
