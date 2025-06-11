class Demo::TransactionGenerator
  include Demo::DataHelper

  def create_transaction!(attributes = {})
    # Separate entry attributes from transaction attributes
    entry_attributes = attributes.extract!(:account, :date, :amount, :currency, :name, :notes)
    transaction_attributes = attributes # category, merchant, etc.

    # Set defaults for entry
    entry_defaults = {
      date: 30.days.ago.to_date,
      amount: 100,
      currency: "USD",
      name: "Demo Transaction"
    }

    # Create entry with transaction as entryable
    entry = Entry.create!(
      entry_defaults.merge(entry_attributes).merge(
        entryable_type: "Transaction",
        entryable_attributes: transaction_attributes
      )
    )

    entry.entryable # Returns the Transaction
  end

  def create_trade!(attributes = {})
    # Separate entry attributes from trade attributes
    entry_attributes = attributes.extract!(:account, :date, :amount, :currency, :name, :notes)
    trade_attributes = attributes # security, qty, price, etc.

    # Validate required trade attributes
    security = trade_attributes[:security] || Security.first
    unless security
      raise ArgumentError, "Security is required for trade creation. Load securities first."
    end

    # Set defaults for entry
    entry_defaults = {
      date: 30.days.ago.to_date,
      currency: "USD",
      name: "Demo Trade"
    }

    # Set defaults for trade
    trade_defaults = {
      qty: 10,
      price: 100,
      currency: "USD"
    }

    # Merge defaults with provided attributes
    final_entry_attributes = entry_defaults.merge(entry_attributes)
    final_trade_attributes = trade_defaults.merge(trade_attributes)
    final_trade_attributes[:security] = security

    # Calculate amount if not provided (qty * price)
    unless final_entry_attributes[:amount]
      final_entry_attributes[:amount] = final_trade_attributes[:qty] * final_trade_attributes[:price]
    end

    # Create entry with trade as entryable
    entry = Entry.create!(
      final_entry_attributes.merge(
        entryable_type: "Trade",
        entryable_attributes: final_trade_attributes
      )
    )

    entry.entryable # Returns the Trade
  end

  def create_realistic_transactions!(family)
    categories = family.categories.limit(10)
    accounts_by_type = group_accounts_by_type(family)
    entries = []

    accounts_by_type[:checking].each do |account|
      entries.concat(create_income_transactions!(account))
      entries.concat(create_expense_transactions!(account, categories))
    end

    accounts_by_type[:credit_cards].each do |account|
      entries.concat(create_credit_card_transactions!(account, categories))
    end

    accounts_by_type[:investments].each do |account|
      entries.concat(create_investment_trades!(account))
    end

    entries
  end

  def create_performance_transactions!(family)
    categories = family.categories.limit(5)
    accounts_by_type = group_accounts_by_type(family)
    entries = []

    accounts_by_type[:checking].each do |account|
      entries.concat(create_bulk_transactions!(account, PERFORMANCE_TRANSACTION_COUNTS[:depository_sample], income: true))
      entries.concat(create_bulk_transactions!(account, PERFORMANCE_TRANSACTION_COUNTS[:depository_sample], income: false))
    end

    accounts_by_type[:credit_cards].each do |account|
      entries.concat(create_bulk_transactions!(account, PERFORMANCE_TRANSACTION_COUNTS[:credit_card_sample], credit_card: true))
    end

    accounts_by_type[:investments].each do |account|
      entries.concat(create_bulk_investment_trades!(account, PERFORMANCE_TRANSACTION_COUNTS[:investment_trades]))
    end

    entries
  end

  private

    def create_income_transactions!(account)
      entries = []

      6.times do |i|
        transaction = create_transaction!(
          account: account,
          name: "Salary #{i + 1}",
          amount: income_amount,
          date: random_date_within_days(90),
          currency: account.currency
        )
        entries << transaction.entry
      end

      entries
    end

    def create_expense_transactions!(account, categories)
      entries = []
      expense_types = [
        { name: "Grocery Store", amount_range: [ 50, 200 ] },
        { name: "Gas Station", amount_range: [ 30, 80 ] },
        { name: "Restaurant", amount_range: [ 25, 150 ] },
        { name: "Online Purchase", amount_range: [ 20, 300 ] }
      ]

      20.times do
        expense_type = expense_types.sample
        transaction = create_transaction!(
          account: account,
          name: expense_type[:name],
          amount: expense_amount(expense_type[:amount_range][0], expense_type[:amount_range][1]),
          date: random_date_within_days(90),
          currency: account.currency,
          category: categories.sample
        )
        entries << transaction.entry
      end

      entries
    end

    def create_credit_card_transactions!(account, categories)
      entries = []

      credit_card_merchants = [
        { name: "Amazon Purchase", amount_range: [ 25, 500 ] },
        { name: "Target", amount_range: [ 30, 150 ] },
        { name: "Coffee Shop", amount_range: [ 5, 15 ] },
        { name: "Department Store", amount_range: [ 50, 300 ] },
        { name: "Subscription Service", amount_range: [ 10, 50 ] }
      ]

      25.times do
        merchant_data = credit_card_merchants.sample
        transaction = create_transaction!(
          account: account,
          name: merchant_data[:name],
          amount: expense_amount(merchant_data[:amount_range][0], merchant_data[:amount_range][1]),
          date: random_date_within_days(90),
          currency: account.currency,
          category: categories.sample
        )
        entries << transaction.entry
      end

      entries
    end

    def create_investment_trades!(account)
      securities = Security.limit(3)
      return [] unless securities.any?

      entries = []

      trade_patterns = [
        { type: "buy", qty_range: [ 1, 50 ] },
        { type: "buy", qty_range: [ 10, 100 ] },
        { type: "sell", qty_range: [ 1, 25 ] }
      ]

      15.times do
        security = securities.sample
        pattern = trade_patterns.sample

        recent_price = security.prices.order(date: :desc).first&.price || 100.0

        trade = create_trade!(
          account: account,
          security: security,
          qty: rand(pattern[:qty_range][0]..pattern[:qty_range][1]),
          price: recent_price * (0.95 + rand * 0.1),
          date: random_date_within_days(90),
          currency: account.currency
        )
        entries << trade.entry
      end

      entries
    end

    def create_bulk_investment_trades!(account, count)
      securities = Security.limit(5)
      return [] unless securities.any?

      entries = []

      count.times do |i|
        security = securities.sample
        recent_price = security.prices.order(date: :desc).first&.price || 100.0

        trade = create_trade!(
          account: account,
          security: security,
          qty: rand(1..100),
          price: recent_price * (0.9 + rand * 0.2),
          date: random_date_within_days(365),
          currency: account.currency,
          name: "Bulk Trade #{i + 1}"
        )
        entries << trade.entry
      end

      entries
    end

    def create_bulk_transactions!(account, count, income: false, credit_card: false)
      entries = []

      count.times do |i|
        amount = if income
          income_amount
        elsif credit_card
          expense_amount(10, 200)
        else
          expense_amount(5, 500)
        end

        name_prefix = if income
          "Bulk Income"
        elsif credit_card
          "Bulk CC Purchase"
        else
          "Bulk Expense"
        end

        transaction = create_transaction!(
          account: account,
          name: "#{name_prefix} #{i + 1}",
          amount: amount,
          date: random_date_within_days(365),
          currency: account.currency
        )
        entries << transaction.entry
      end

      entries
    end

    def expense_amount(min_or_range = :small, max = nil)
      if min_or_range.is_a?(Symbol)
        case min_or_range
        when :small then random_amount(10, 200)
        when :medium then random_amount(50, 500)
        when :large then random_amount(200, 1000)
        when :credit_card then random_amount(20, 300)
        else random_amount(10, 500)
        end
      else
        max_amount = max || (min_or_range + 100)
        random_amount(min_or_range, max_amount)
      end
    end

    def income_amount(type = :salary)
      case type
      when :salary then random_amount(3000, 7000)
      when :dividend then random_amount(100, 500)
      when :interest then random_amount(50, 200)
      else random_amount(1000, 5000)
      end
    end
end
