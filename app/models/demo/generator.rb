class Demo::Generator
  # Generate empty family - no financial data
  def generate_empty_data!
    puts "🧹 Clearing existing data..."
    clear_all_data!

    puts "👥 Creating empty family..."
    create_family_and_users!("Demo Family", "user@maybe.local", onboarded: true, subscribed: true)

    puts "✅ Empty demo data loaded successfully!"
  end

  # Generate new user family - no financial data, needs onboarding
  def generate_new_user_data!
    puts "🧹 Clearing existing data..."
    clear_all_data!

    puts "👥 Creating new user family..."
    create_family_and_users!("Demo Family", "user@maybe.local", onboarded: false, subscribed: false)

    puts "✅ New user demo data loaded successfully!"
  end

  # Generate comprehensive realistic demo data with multi-currency
  def generate_default_data!
    puts "🧹 Clearing existing data..."
    clear_all_data!

    puts "👥 Creating demo family..."
    family = create_family_and_users!("Demo Family", "user@maybe.local", onboarded: true, subscribed: true)

    puts "📊 Creating realistic financial data..."
    create_realistic_categories!(family)
    create_realistic_accounts!(family)
    create_realistic_transactions!(family)
    create_realistic_budget!(family)

    puts "🔄 Syncing accounts..."
    sync_family_accounts!(family)

    puts "✅ Realistic demo data loaded successfully!"
  end

  # Multi-currency support (keeping existing functionality)
  def generate_multi_currency_data!(family_names)
    generate_for_scenario(:multi_currency, family_names)
  end

  private

    def clear_all_data!
      family_count = Family.count
      if family_count > 50
        raise "Too much data to clear efficiently (#{family_count} families). Run 'rails db:reset' instead."
      end
      Demo::DataCleaner.new.destroy_everything!
    end

    def create_family_and_users!(family_name, email, onboarded:, subscribed:)
      family = Family.create!(
        name: family_name,
        currency: "USD",
        locale: "en",
        country: "US",
        timezone: "America/New_York",
        date_format: "%m-%d-%Y"
      )

      family.start_subscription!("sub_demo_123") if subscribed

      # Admin user
      family.users.create!(
        email: email,
        first_name: "Demo (admin)",
        last_name: "Maybe",
        role: "admin",
        password: "password",
        onboarded_at: onboarded ? Time.current : nil
      )

      # Member user
      family.users.create!(
        email: "partner_#{email}",
        first_name: "Demo (member)",
        last_name: "Maybe",
        role: "member",
        password: "password",
        onboarded_at: onboarded ? Time.current : nil
      )

      family
    end

    def create_realistic_categories!(family)
      # Income categories
      @salary_cat = family.categories.create!(name: "Salary", color: "#10b981", classification: "income")
      @freelance_cat = family.categories.create!(name: "Freelance", color: "#059669", classification: "income")
      @investment_income_cat = family.categories.create!(name: "Investment Income", color: "#047857", classification: "income")

      # Expense categories with subcategories
      @housing_cat = family.categories.create!(name: "Housing", color: "#dc2626", classification: "expense")
      @rent_cat = family.categories.create!(name: "Rent/Mortgage", parent: @housing_cat, color: "#b91c1c", classification: "expense")
      @utilities_cat = family.categories.create!(name: "Utilities", parent: @housing_cat, color: "#991b1b", classification: "expense")

      @food_cat = family.categories.create!(name: "Food & Dining", color: "#ea580c", classification: "expense")
      @groceries_cat = family.categories.create!(name: "Groceries", parent: @food_cat, color: "#c2410c", classification: "expense")
      @restaurants_cat = family.categories.create!(name: "Restaurants", parent: @food_cat, color: "#9a3412", classification: "expense")

      @transportation_cat = family.categories.create!(name: "Transportation", color: "#2563eb", classification: "expense")
      @gas_cat = family.categories.create!(name: "Gas", parent: @transportation_cat, color: "#1d4ed8", classification: "expense")

      @entertainment_cat = family.categories.create!(name: "Entertainment", color: "#7c3aed", classification: "expense")
      @healthcare_cat = family.categories.create!(name: "Healthcare", color: "#db2777", classification: "expense")
      @shopping_cat = family.categories.create!(name: "Shopping", color: "#059669", classification: "expense")
      @travel_cat = family.categories.create!(name: "Travel", color: "#0891b2", classification: "expense")
    end

    def create_realistic_accounts!(family)
      # Checking accounts (USD)
      @chase_checking = family.accounts.create!(accountable: Depository.new, name: "Chase Premier Checking", balance: 0, currency: "USD")
      @ally_checking = family.accounts.create!(accountable: Depository.new, name: "Ally Online Checking", balance: 0, currency: "USD")

      # Savings account (USD)
      @marcus_savings = family.accounts.create!(accountable: Depository.new, name: "Marcus High-Yield Savings", balance: 0, currency: "USD")

      # Credit cards (USD)
      @amex_gold = family.accounts.create!(accountable: CreditCard.new, name: "Amex Gold Card", balance: 0, currency: "USD")
      @chase_sapphire = family.accounts.create!(accountable: CreditCard.new, name: "Chase Sapphire Reserve", balance: 0, currency: "USD")

      # Investment accounts (USD + GBP)
      @vanguard_401k = family.accounts.create!(accountable: Investment.new, name: "Vanguard 401(k)", balance: 0, currency: "USD")
      @schwab_brokerage = family.accounts.create!(accountable: Investment.new, name: "Charles Schwab Brokerage", balance: 0, currency: "USD")
      @uk_isa = family.accounts.create!(accountable: Investment.new, name: "Vanguard UK ISA", balance: 0, currency: "GBP")

      # Property and mortgage (USD)
      @home = family.accounts.create!(accountable: Property.new, name: "Primary Residence", balance: 0, currency: "USD")
      @mortgage = family.accounts.create!(accountable: Loan.new, name: "Home Mortgage", balance: 0, currency: "USD")

      # EUR vacation account
      @eu_checking = family.accounts.create!(accountable: Depository.new, name: "Deutsche Bank EUR Account", balance: 0, currency: "EUR")
    end

    def create_realistic_transactions!(family)
      load_securities!

      # Salary income (bi-weekly)
      create_transaction!(@chase_checking, -8500, "Acme Corp Payroll", @salary_cat, 14.days.ago)
      create_transaction!(@chase_checking, -8500, "Acme Corp Payroll", @salary_cat, 28.days.ago)
      create_transaction!(@chase_checking, -8500, "Acme Corp Payroll", @salary_cat, 42.days.ago)
      create_transaction!(@chase_checking, -8500, "Acme Corp Payroll", @salary_cat, 56.days.ago)
      create_transaction!(@chase_checking, -8500, "Acme Corp Payroll", @salary_cat, 70.days.ago)
      create_transaction!(@chase_checking, -8500, "Acme Corp Payroll", @salary_cat, 84.days.ago)

      # Freelance income
      create_transaction!(@ally_checking, -3500, "Design Project Payment", @freelance_cat, 20.days.ago)
      create_transaction!(@ally_checking, -2800, "Consulting Fee", @freelance_cat, 45.days.ago)
      create_transaction!(@ally_checking, -4200, "Design Retainer Q4", @freelance_cat, 60.days.ago)

      # Investment income
      create_transaction!(@schwab_brokerage, -850, "Dividend Payment", @investment_income_cat, 25.days.ago)
      create_transaction!(@vanguard_401k, -420, "401k Employer Match", @salary_cat, 28.days.ago)

      # Housing expenses
      create_transaction!(@chase_checking, 3200, "Rent Payment", @rent_cat, 1.day.ago)
      create_transaction!(@chase_checking, 3200, "Rent Payment", @rent_cat, 32.days.ago)
      create_transaction!(@chase_checking, 3200, "Rent Payment", @rent_cat, 63.days.ago)
      create_transaction!(@chase_checking, 185, "ConEd Electric", @utilities_cat, 5.days.ago)
      create_transaction!(@chase_checking, 95, "Verizon Internet", @utilities_cat, 8.days.ago)

      # Food & dining (reduced amounts)
      create_transaction!(@amex_gold, 165, "Whole Foods Market", @groceries_cat, 2.days.ago)
      create_transaction!(@amex_gold, 78, "Joe's Pizza", @restaurants_cat, 3.days.ago)
      create_transaction!(@amex_gold, 145, "Trader Joe's", @groceries_cat, 6.days.ago)
      create_transaction!(@amex_gold, 95, "Blue Hill Restaurant", @restaurants_cat, 7.days.ago)
      create_transaction!(@chase_sapphire, 185, "Michelin Star Dinner", @restaurants_cat, 12.days.ago)

      # Transportation
      create_transaction!(@chase_checking, 65, "Shell Gas Station", @gas_cat, 4.days.ago)
      create_transaction!(@chase_checking, 72, "Mobil Gas", @gas_cat, 18.days.ago)

      # Entertainment & subscriptions
      create_transaction!(@amex_gold, 15, "Netflix", @entertainment_cat, 1.day.ago)
      create_transaction!(@amex_gold, 12, "Spotify Premium", @entertainment_cat, 3.days.ago)
      create_transaction!(@chase_sapphire, 45, "Movie Theater", @entertainment_cat, 9.days.ago)

      # Healthcare
      create_transaction!(@chase_checking, 25, "CVS Pharmacy", @healthcare_cat, 11.days.ago)
      create_transaction!(@chase_checking, 350, "Dr. Smith Office Visit", @healthcare_cat, 22.days.ago)

      # Shopping
      create_transaction!(@amex_gold, 125, "Amazon Purchase", @shopping_cat, 6.days.ago)
      create_transaction!(@chase_sapphire, 89, "Target", @shopping_cat, 15.days.ago)

      # European vacation (EUR)
      create_transaction!(@eu_checking, 850, "Hotel Paris", @travel_cat, 35.days.ago)
      create_transaction!(@eu_checking, 125, "Restaurant Lyon", @restaurants_cat, 36.days.ago)
      create_transaction!(@eu_checking, 65, "Train Ticket", @transportation_cat, 37.days.ago)

      # Investment transactions (adjusted for target net worth)
      security = Security.first
      if security
        create_investment_transaction!(@vanguard_401k, security, 150, 150, 25.days.ago, "401k Contribution")
        create_investment_transaction!(@vanguard_401k, security, 200, 145, 50.days.ago, "401k Rollover")
        create_investment_transaction!(@schwab_brokerage, security, 300, 150, 40.days.ago, "Stock Purchase")
        create_investment_transaction!(@schwab_brokerage, security, 150, 155, 65.days.ago, "Additional Investment")
        create_investment_transaction!(@uk_isa, security, 60, 120, 55.days.ago, "UK Stock Purchase") # GBP
      end

      # Property and debt
      create_transaction!(@home, -750000, "Home Purchase", nil, 90.days.ago)
      create_transaction!(@mortgage, 450000, "Mortgage Principal", nil, 90.days.ago)

      # Add positive balance to EUR account first
      create_transaction!(@eu_checking, -2500, "EUR Account Funding", nil, 40.days.ago)

      # Credit card payments and transfers
      create_transfer!(@chase_checking, @amex_gold, 1250, "Amex Payment", 10.days.ago)
      create_transfer!(@chase_checking, @chase_sapphire, 850, "Sapphire Payment", 12.days.ago)
      create_transfer!(@ally_checking, @marcus_savings, 5000, "Savings Transfer", 15.days.ago)

      # Additional income and transfers to boost net worth
      create_transaction!(@chase_checking, -12000, "Year-end Bonus", @salary_cat, 30.days.ago)
      create_transaction!(@marcus_savings, -15000, "Tax Refund", @salary_cat, 50.days.ago)
      create_transaction!(@ally_checking, -5000, "Stock Sale Proceeds", @investment_income_cat, 35.days.ago)

      # Additional savings transfer
      create_transfer!(@chase_checking, @marcus_savings, 10000, "Additional Savings", 25.days.ago)
    end

    def create_realistic_budget!(family)
      current_month = Date.current.beginning_of_month
      end_of_month = current_month.end_of_month
      budget = family.budgets.create!(
        start_date: current_month,
        end_date: end_of_month,
        currency: "USD",
        budgeted_spending: 7100,
        expected_income: 17000
      )

      # Budget allocations based on realistic spending
      budget.budget_categories.create!(category: @housing_cat, budgeted_spending: 3500, currency: "USD")
      budget.budget_categories.create!(category: @food_cat, budgeted_spending: 800, currency: "USD")
      budget.budget_categories.create!(category: @transportation_cat, budgeted_spending: 400, currency: "USD")
      budget.budget_categories.create!(category: @entertainment_cat, budgeted_spending: 300, currency: "USD")
      budget.budget_categories.create!(category: @healthcare_cat, budgeted_spending: 500, currency: "USD")
      budget.budget_categories.create!(category: @shopping_cat, budgeted_spending: 600, currency: "USD")
      budget.budget_categories.create!(category: @travel_cat, budgeted_spending: 1000, currency: "USD")
    end

    def create_transaction!(account, amount, name, category, date)
      account.entries.create!(
        entryable: Transaction.new(category: category),
        amount: amount,
        name: name,
        currency: account.currency,
        date: date
      )
    end

    def create_investment_transaction!(account, security, qty, price, date, name)
      account.entries.create!(
        entryable: Trade.new(security: security, qty: qty, price: price, currency: account.currency),
        amount: -(qty * price),
        name: name,
        currency: account.currency,
        date: date
      )
    end

    def create_transfer!(from_account, to_account, amount, name, date)
      outflow = from_account.entries.create!(
        entryable: Transaction.new,
        amount: amount,
        name: name,
        currency: from_account.currency,
        date: date
      )
      inflow = to_account.entries.create!(
        entryable: Transaction.new,
        amount: -amount,
        name: name,
        currency: to_account.currency,
        date: date
      )
      Transfer.create!(inflow_transaction: inflow.entryable, outflow_transaction: outflow.entryable)
    end

    def load_securities!
      return if Security.exists?

      Security.create!([
        { ticker: "VTI", name: "Vanguard Total Stock Market ETF", country_code: "US" },
        { ticker: "VXUS", name: "Vanguard Total International Stock ETF", country_code: "US" },
        { ticker: "BND", name: "Vanguard Total Bond Market ETF", country_code: "US" }
      ])
    end

    def sync_family_accounts!(family)
      family.accounts.each do |account|
        sync = Sync.create!(syncable: account)
        sync.perform
      end
    end
end
