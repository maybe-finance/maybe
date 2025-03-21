class Assistant::Function::GetTransactions < Assistant::Function
  class << self
    def name
      "get_transactions"
    end

    def description
      "Get transactions filtered by date range and/or category"
    end

    def parameters
      {
        type: "object",
        properties: {
          start_date: {
            type: "string",
            format: "date",
            description: "Start date for transactions (YYYY-MM-DD)"
          },
          end_date: {
            type: "string",
            format: "date",
            description: "End date for transactions (YYYY-MM-DD)"
          },
          category_name: {
            type: "string",
            description: "Filter transactions by category name"
          },
          limit: {
            type: "integer",
            description: "Maximum number of transactions to return",
            default: 10
          }
        },
        required: []
      }
    end
  end

  def call(params = {})
    start_date = parse_date(params["start_date"], 30.days.ago.to_date)
    end_date = parse_date(params["end_date"], Date.today)
    category_name = params["category_name"]
    limit = params["limit"] || 10

    transactions = fetch_transactions(start_date, end_date, category_name, limit)
    category = find_category(category_name) if category_name.present?

    {
      period: format_period(start_date, end_date),
      transactions: format_transactions(transactions),
      count: transactions.size,
      currency: family.currency,
      search_info: format_search_info(category_name, category)
    }
  end

  private

    def parse_date(date_string, default)
      date_string ? Date.parse(date_string) : default
    end

    def fetch_transactions(start_date, end_date, category_name, limit)
      transactions = family.transactions.active
        .in_period(Period.new(start_date: start_date, end_date: end_date))
        .includes(:account_entry, :category, :merchant)
        .order("account_entries.date DESC")

      if category_name.present? && (category = find_category(category_name))
        transactions = transactions.where(category_id: category.id)
      end

      transactions.limit(limit)
    end

    def find_category(name)
      category = family.categories.find_by(name: name)
      return category if category

      categories = family.categories.where("LOWER(name) LIKE ?", "%#{name.downcase}%")
      categories.first if categories.any?
    end

    def format_period(start_date, end_date)
      {
        start_date: start_date.to_s,
        end_date: end_date.to_s
      }
    end

    def format_transactions(transactions)
      transactions.map do |transaction|
        entry = transaction.account_entry
        {
          date: entry.date,
          name: entry.name,
          amount: format_currency(entry.amount),
          category: transaction.category&.name || "Uncategorized",
          merchant: transaction.merchant&.name
        }
      end
    end

    def format_search_info(category_name, category)
      {
        category_query: category_name,
        matched_category: category&.name
      }
    end

    def format_currency(amount)
      Money.new(amount, family.currency).format
    end
end
