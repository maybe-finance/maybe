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

    # Create initial valuations for accounts before other transactions
    entries.concat(create_initial_valuations!(family))

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

    # Update account balances to match transaction sums
    update_account_balances_from_transactions!(family)

    entries
  end

  def create_performance_transactions!(family)
    categories = family.categories.limit(5)
    accounts_by_type = group_accounts_by_type(family)
    entries = []

    # Create initial valuations for accounts before other transactions
    entries.concat(create_initial_valuations!(family))

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

    # Update account balances to match transaction sums
    update_account_balances_from_transactions!(family)

    entries
  end

  # Create initial valuations for accounts to establish realistic starting values
  # This is more appropriate than fake transactions
  def create_initial_valuations!(family)
    entries = []

    family.accounts.each do |account|
      initial_value = case account.accountable_type
      when "Loan"
        case account.name
        when /Mortgage/i then 300000 # Initial mortgage debt
        when /Auto/i, /Car/i then 15000 # Initial car loan debt
        else 10000 # Other loan debt
        end
      when "CreditCard"
        5000 # Initial credit card debt
      when "Property"
        500000 # Initial property value
      when "Vehicle"
        25000 # Initial vehicle value
      when "OtherAsset"
        5000 # Initial other asset value
      when "OtherLiability"
        2000 # Initial other liability debt
      else
        next # Skip accounts that don't need initial valuations
      end

      # Create valuation entry
      entry = Entry.create!(
        account: account,
        amount: initial_value,
        name: "Initial #{account.accountable_type.humanize.downcase} valuation",
        date: 2.years.ago.to_date,
        currency: account.currency,
        entryable_type: "Valuation",
        entryable_attributes: {}
      )
      entries << entry
    end

    entries
  end

  # Update account balances to match the sum of their transactions and valuations
  # This ensures realistic balances without artificial balancing transactions
  def update_account_balances_from_transactions!(family)
    family.accounts.each do |account|
      transaction_sum = account.entries
                               .where(entryable_type: [ "Transaction", "Trade", "Valuation" ])
                               .sum(:amount)

      # Calculate realistic balance based on transaction sum and account type
      # For assets: balance should be positive, so we negate the transaction sum
      # For liabilities: balance should reflect debt owed
      new_balance = case account.classification
      when "asset"
        -transaction_sum # Assets: negative transaction sum = positive balance
      when "liability"
        transaction_sum # Liabilities: positive transaction sum = positive debt balance
      else
        -transaction_sum
      end

      # Ensure minimum realistic balance
      new_balance = [ new_balance, minimum_realistic_balance(account) ].max

      account.update!(balance: new_balance)
    end
  end

  private

    def create_income_transactions!(account)
      entries = []

      6.times do |i|
        transaction = create_transaction!(
          account: account,
          name: "Salary #{i + 1}",
          amount: -income_amount,
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

      # Handle credit cards specially to ensure balanced purchases and payments
      if account.accountable_type == "CreditCard"
        # Create a mix of purchases (positive) and payments (negative)
        purchase_count = (count * 0.8).to_i # 80% purchases
        payment_count = count - purchase_count # 20% payments

        total_purchases = 0

        # Create purchases first
        purchase_count.times do |i|
          amount = expense_amount(10, 200) # Credit card purchases (positive)
          total_purchases += amount

          transaction = create_transaction!(
            account: account,
            name: "Bulk CC Purchase #{i + 1}",
            amount: amount,
            date: random_date_within_days(365),
            currency: account.currency
          )
          entries << transaction.entry
        end

        # Create reasonable payments (negative amounts)
        # Payments should be smaller than total debt available
        initial_debt = 5000 # From initial valuation
        available_debt = initial_debt + total_purchases

        payment_count.times do |i|
          # Payment should be reasonable portion of available debt
          max_payment = [ available_debt * 0.1, 500 ].max # 10% of debt or min $500
          amount = -expense_amount(50, max_payment.to_i) # Payment (negative)

          transaction = create_transaction!(
            account: account,
            name: "Credit card payment #{i + 1}",
            amount: amount,
            date: random_date_within_days(365),
            currency: account.currency
          )
          entries << transaction.entry
        end

      else
        # Regular handling for non-credit card accounts
        count.times do |i|
          amount = if income
            -income_amount # Income (negative)
          elsif credit_card
            expense_amount(10, 200) # This path shouldn't be reached for actual credit cards
          else
            expense_amount(5, 500) # Regular expenses (positive)
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

    # Determine minimum realistic balance for account type
    def minimum_realistic_balance(account)
      case account.accountable_type
      when "Depository"
        account.subtype == "savings" ? 1000 : 500
      when "Investment"
        5000
      when "Property"
        100000
      when "Vehicle"
        5000
      when "OtherAsset"
        100
      when "CreditCard", "Loan", "OtherLiability"
        100 # Minimum debt
      else
        100
      end
    end
end
