class Demo::Generator
  # Generate empty family - no financial data
  def generate_empty_data!(skip_clear: false)
    unless skip_clear
      puts "🧹 Clearing existing data..."
      clear_all_data!
    end

    puts "👥 Creating empty family..."
    create_family_and_users!("Demo Family", "user@maybe.local", onboarded: true, subscribed: true)

    puts "✅ Empty demo data loaded successfully!"
  end

  # Generate new user family - no financial data, needs onboarding
  def generate_new_user_data!(skip_clear: false)
    unless skip_clear
      puts "🧹 Clearing existing data..."
      clear_all_data!
    end

    puts "👥 Creating new user family..."
    create_family_and_users!("Demo Family", "user@maybe.local", onboarded: false, subscribed: false)

    puts "✅ New user demo data loaded successfully!"
  end

  # Generate comprehensive realistic demo data with multi-currency
  def generate_default_data!(skip_clear: false, email: "user@maybe.local")
    if skip_clear
      puts "⏭️  Skipping data clearing (appending new family)..."
    else
      puts "🧹 Clearing existing data..."
      clear_all_data!
    end

    puts "👥 Creating demo family..."
    family = create_family_and_users!("Demo Family", email, onboarded: true, subscribed: true)

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
      # Income categories (3 total)
      @salary_cat = family.categories.create!(name: "Salary", color: "#10b981", classification: "income")
      @freelance_cat = family.categories.create!(name: "Freelance", color: "#059669", classification: "income")
      @investment_income_cat = family.categories.create!(name: "Investment Income", color: "#047857", classification: "income")

      # Expense categories with subcategories (12 total)
      @housing_cat = family.categories.create!(name: "Housing", color: "#dc2626", classification: "expense")
      @rent_cat = family.categories.create!(name: "Rent/Mortgage", parent: @housing_cat, color: "#b91c1c", classification: "expense")
      @utilities_cat = family.categories.create!(name: "Utilities", parent: @housing_cat, color: "#991b1b", classification: "expense")

      @food_cat = family.categories.create!(name: "Food & Dining", color: "#ea580c", classification: "expense")
      @groceries_cat = family.categories.create!(name: "Groceries", parent: @food_cat, color: "#c2410c", classification: "expense")
      @restaurants_cat = family.categories.create!(name: "Restaurants", parent: @food_cat, color: "#9a3412", classification: "expense")
      @coffee_cat = family.categories.create!(name: "Coffee & Takeout", parent: @food_cat, color: "#7c2d12", classification: "expense")

      @transportation_cat = family.categories.create!(name: "Transportation", color: "#2563eb", classification: "expense")
      @gas_cat = family.categories.create!(name: "Gas", parent: @transportation_cat, color: "#1d4ed8", classification: "expense")
      @car_payment_cat = family.categories.create!(name: "Car Payment", parent: @transportation_cat, color: "#1e40af", classification: "expense")

      @entertainment_cat = family.categories.create!(name: "Entertainment", color: "#7c3aed", classification: "expense")
      @healthcare_cat = family.categories.create!(name: "Healthcare", color: "#db2777", classification: "expense")
      @shopping_cat = family.categories.create!(name: "Shopping", color: "#059669", classification: "expense")
      @travel_cat = family.categories.create!(name: "Travel", color: "#0891b2", classification: "expense")
      @personal_care_cat = family.categories.create!(name: "Personal Care", color: "#be185d", classification: "expense")
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

      puts "   📈 Generating salary history (12 years)..."
      generate_salary_history!

      puts "   🏠 Generating housing transactions..."
      generate_housing_transactions!

      puts "   🍕 Generating food & dining transactions..."
      generate_food_transactions!

      puts "   🚗 Generating transportation transactions..."
      generate_transportation_transactions!

      puts "   🎬 Generating entertainment transactions..."
      generate_entertainment_transactions!

      puts "   🛒 Generating shopping transactions..."
      generate_shopping_transactions!

      puts "   ⚕️ Generating healthcare transactions..."
      generate_healthcare_transactions!

      puts "   ✈️ Generating travel transactions..."
      generate_travel_transactions!

      puts "   💅 Generating personal care transactions..."
      generate_personal_care_transactions!

      puts "   💰 Generating investment transactions..."
      generate_investment_transactions!

      puts "   🏡 Generating major purchases..."
      generate_major_purchases!

      puts "   💳 Generating transfers and payments..."
      generate_transfers_and_payments!

      puts "   📊 Generated approximately #{Entry.joins(:account).where(accounts: { family_id: family.id }).count} transactions"
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

    # Helper method to get weighted random date (favoring recent years)
    def weighted_random_date
      # 60% chance in last 3 years, 40% in years 4-12
      if rand < 0.6
        rand(3.years.ago.to_date..Date.current)
      else
        rand(12.years.ago.to_date..3.years.ago.to_date)
      end
    end

    # Helper method to get random accounts for transactions
    def random_checking_account
      [ @chase_checking, @ally_checking ].sample
    end

    def generate_salary_history!
      start_date = 12.years.ago.to_date
      base_salary = 3500 # Starting bi-weekly salary (much lower)

      (start_date..Date.current).each do |date|
        next unless date.wday == 5 && (date.cweek % 2 == 0) # Every other Friday

        # 3.5% annual salary growth
        years_since_start = (date - start_date) / 365.25
        current_salary = (base_salary * (1.035 ** years_since_start)).round

        create_transaction!(@chase_checking, -current_salary, "Acme Corp Payroll", @salary_cat, date)

        # 401k employer match (every paycheck)
        match_amount = (current_salary * 0.04).round
        create_transaction!(@vanguard_401k, -match_amount, "401k Employer Match", @salary_cat, date)

        # Annual bonus in December
        if date.month == 12 && date.day > 15
          bonus = (current_salary * 3).round # Smaller bonus
          create_transaction!(@chase_checking, -bonus, "Year-end Bonus", @salary_cat, date)
        end
      end

      # Quarterly freelance income (reduced count and amounts)
      15.times do
        date = weighted_random_date
        amount = rand(1200..3000) # Lower amounts
        account = [ @ally_checking, @chase_checking ].sample
        projects = [ "Design Project", "Consulting Work", "Web Development", "Brand Strategy", "UI/UX Design" ]
        create_transaction!(account, -amount, projects.sample, @freelance_cat, date)
      end

      # Investment income (reduced count and amounts)
      12.times do
        date = weighted_random_date
        next if date < 2.years.ago.to_date # Only recent investment income
        amount = rand(100..400) # Lower amounts
        create_transaction!(@schwab_brokerage, -amount, "Dividend Payment", @investment_income_cat, date)
      end
    end

    def generate_housing_transactions!
      start_date = 12.years.ago.to_date
      base_rent = 1800 # Starting rent (lower)

      # Monthly rent/mortgage payments
      (start_date..Date.current).each do |date|
        next unless date.day == 1 # First of month

        # 2.5% annual rent increases
        years_since_start = (date - start_date) / 365.25
        current_rent = (base_rent * (1.025 ** years_since_start)).round

        # Switch to mortgage after home purchase
        if date >= 5.years.ago.to_date
          # Mortgage payment from checking account (positive expense)
          create_transaction!(@chase_checking, current_rent, "Mortgage Payment", @rent_cat, date)
          # Principal payment reduces mortgage debt (negative transaction)
          principal_payment = (current_rent * 0.3).round # ~30% goes to principal
          create_transaction!(@mortgage, -principal_payment, "Principal Payment", nil, date)
        else
          create_transaction!(@chase_checking, current_rent, "Rent Payment", @rent_cat, date)
        end
      end

      # Monthly utilities
      utilities = [
        { name: "ConEd Electric", range: 120..250 },
        { name: "Verizon Internet", range: 85..105 },
        { name: "Water & Sewer", range: 45..75 },
        { name: "Gas Bill", range: 60..180 }
      ]

      utilities.each do |utility|
        (start_date..Date.current).each do |date|
          next unless date.day.between?(5, 15) && rand < 0.3 # Random days, not every month
          amount = rand(utility[:range])
          create_transaction!(@chase_checking, amount, utility[:name], @utilities_cat, date)
        end
      end
    end

    def generate_food_transactions!
      # Weekly groceries (checking account only now)
      150.times do
        date = weighted_random_date
        amount = rand(60..180) # Realistic amounts
        stores = [ "Whole Foods", "Trader Joe's", "Safeway", "Stop & Shop", "Fresh Market" ]
        create_transaction!(@chase_checking, amount, "#{stores.sample} Market", @groceries_cat, date)
      end

      # Restaurant dining (checking account only - credit card dining handled deterministically)
      100.times do
        date = weighted_random_date
        amount = rand(25..60) # Smaller amounts for checking
        restaurants = [ "Pizza Corner", "Sushi Place", "Italian Kitchen", "Mexican Grill", "Greek Taverna" ]
        create_transaction!(@chase_checking, amount, restaurants.sample, @restaurants_cat, date)
      end

      # Coffee & takeout (checking account only)
      60.times do
        date = weighted_random_date
        amount = rand(8..20)
        places = [ "Local Coffee", "Dunkin'", "Corner Deli", "Food Truck" ]
        create_transaction!(@chase_checking, amount, places.sample, @coffee_cat, date)
      end
    end

    def generate_transportation_transactions!
      # Gas stations (checking account only)
      60.times do
        date = weighted_random_date
        amount = rand(35..75)
        stations = [ "Shell", "Exxon", "BP", "Chevron", "Mobil", "Sunoco" ]
        create_transaction!(@chase_checking, amount, "#{stations.sample} Gas", @gas_cat, date)
      end

      # Car payment (monthly for 6 years)
      car_payment_start = 6.years.ago.to_date
      car_payment_end = 1.year.ago.to_date

      (car_payment_start..car_payment_end).each do |date|
        next unless date.day == 15 # 15th of month
        create_transaction!(@chase_checking, 385, "Auto Loan Payment", @car_payment_cat, date)
      end
    end

    def generate_entertainment_transactions!
      # Monthly subscriptions (checking account)
      subscriptions = [
        { name: "Netflix", amount: 15 },
        { name: "Spotify Premium", amount: 12 },
        { name: "Disney+", amount: 8 },
        { name: "HBO Max", amount: 16 },
        { name: "Amazon Prime", amount: 14 }
      ]

      subscriptions.each do |sub|
        (12.years.ago.to_date..Date.current).each do |date|
          next unless date.day == rand(1..28) && rand < 0.08 # Monthly-ish
          create_transaction!(@chase_checking, sub[:amount], sub[:name], @entertainment_cat, date)
        end
      end

      # Random entertainment (checking account only - premium entertainment handled in credit card cycles)
      80.times do
        date = weighted_random_date
        amount = rand(15..60) # Smaller amounts for checking
        activities = [ "Movie Theater", "Sports Game", "Museum", "Comedy Club", "Bowling", "Mini Golf", "Arcade" ]
        create_transaction!(@chase_checking, amount, activities.sample, @entertainment_cat, date)
      end
    end

    def generate_shopping_transactions!
      # Online shopping (checking account only - premium shopping handled in credit card cycles)
      100.times do
        date = weighted_random_date
        amount = rand(25..80) # Smaller amounts for checking
        stores = [ "Target.com", "Walmart", "Costco" ]
        create_transaction!(@chase_checking, amount, "#{stores.sample} Purchase", @shopping_cat, date)
      end

      # In-store shopping (checking account only)
      60.times do
        date = weighted_random_date
        amount = rand(30..70) # Smaller amounts for checking
        stores = [ "Target", "REI", "Barnes & Noble", "GameStop" ]
        create_transaction!(@chase_checking, amount, stores.sample, @shopping_cat, date)
      end
    end

    def generate_healthcare_transactions!
      # Doctor visits (reduced count)
      25.times do
        date = weighted_random_date
        amount = rand(180..450)
        providers = [ "Dr. Smith", "Dr. Johnson", "Dr. Williams", "Specialist Visit", "Urgent Care" ]
        create_transaction!(@chase_checking, amount, providers.sample, @healthcare_cat, date)
      end

      # Pharmacy (checking account only)
      40.times do
        date = weighted_random_date
        amount = rand(15..85)
        pharmacies = [ "CVS Pharmacy", "Walgreens", "Rite Aid", "Local Pharmacy" ]
        create_transaction!(@chase_checking, amount, pharmacies.sample, @healthcare_cat, date)
      end
    end

    def generate_travel_transactions!
      # Major vacations (reduced count - premium travel handled in credit card cycles)
      8.times do
        date = weighted_random_date

        # Smaller local trips from checking
        hotel_amount = rand(200..500)
        hotels = [ "Local Hotel", "B&B", "Nearby Resort" ]
        if rand < 0.3 && date > 3.years.ago.to_date # Some EUR transactions
          create_transaction!(@eu_checking, hotel_amount, hotels.sample, @travel_cat, date)
        else
          create_transaction!(@chase_checking, hotel_amount, hotels.sample, @travel_cat, date)
        end

        # Domestic flights (smaller amounts)
        flight_amount = rand(200..400)
        create_transaction!(@chase_checking, flight_amount, "Domestic Flight", @travel_cat, date + rand(1..5).days)

        # Local activities
        activity_amount = rand(50..150)
        activities = [ "Local Tour", "Museum Tickets", "Activity Pass" ]
        create_transaction!(@chase_checking, activity_amount, activities.sample, @travel_cat, date + rand(1..7).days)
      end
    end

    def generate_personal_care_transactions!
      # Gym membership
      (12.years.ago.to_date..Date.current).each do |date|
        next unless date.day == 1 && rand < 0.8 # Monthly
        create_transaction!(@chase_checking, 45, "Gym Membership", @personal_care_cat, date)
      end

      # Beauty/grooming (checking account only)
      40.times do
        date = weighted_random_date
        amount = rand(25..80)
        services = [ "Hair Salon", "Barber Shop", "Nail Salon" ]
        create_transaction!(@chase_checking, amount, services.sample, @personal_care_cat, date)
      end
    end

    def generate_investment_transactions!
      security = Security.first
      return unless security

      # 401k contributions (bi-weekly)
      (12.years.ago.to_date..Date.current).each do |date|
        next unless date.wday == 5 && (date.cweek % 2 == 0) # Every other Friday

        years_since_start = (date - 12.years.ago.to_date) / 365.25
        contribution = (100 + (years_since_start * 20)).round # Much smaller contributions
        price = rand(80..200) # Random stock price
        qty = (contribution.to_f / price).round(2)

        create_investment_transaction!(@vanguard_401k, security, qty, price, date, "401k Contribution")
      end

      # Brokerage investments (reduced)
      15.times do
        date = weighted_random_date
        next if date < 4.years.ago.to_date # Only recent brokerage activity

        investment = rand(200..800) # Much smaller amounts
        price = rand(80..200)
        qty = (investment.to_f / price).round(2)

        create_investment_transaction!(@schwab_brokerage, security, qty, price, date, "Stock Purchase")
      end

      # UK ISA investments (reduced)
      6.times do
        date = weighted_random_date
        next if date < 3.years.ago.to_date

        investment = rand(100..300) # Smaller GBP amounts
        price = rand(60..150) # GBP price
        qty = (investment.to_f / price).round(2)

        create_investment_transaction!(@uk_isa, security, qty, price, date, "ISA Investment")
      end
    end

    def generate_major_purchases!
      # Home purchase (5 years ago) - smaller home
      home_date = 5.years.ago.to_date
      create_transaction!(@home, -450000, "Home Purchase", nil, home_date)
      create_transaction!(@mortgage, 320000, "Mortgage Principal", nil, home_date) # Positive for liability debt

      # Initial account funding (much lower)
      create_transaction!(@chase_checking, -5000, "Initial Deposit", @salary_cat, 12.years.ago.to_date)
      create_transaction!(@ally_checking, -2000, "Initial Deposit", @salary_cat, 12.years.ago.to_date)
      create_transaction!(@marcus_savings, -10000, "Initial Savings", @salary_cat, 12.years.ago.to_date)
      create_transaction!(@eu_checking, -5000, "EUR Account Opening", nil, 4.years.ago.to_date)

      # Car purchase (6 years ago)
      create_transaction!(@chase_checking, 15000, "Car Down Payment", @transportation_cat, 6.years.ago.to_date)

      # Major expenses (reduced amounts)
      create_transaction!(@chase_checking, 12000, "Kitchen Renovation", @utilities_cat, 2.years.ago.to_date)
      create_transaction!(@chase_checking, 8000, "Bathroom Remodel", @utilities_cat, 1.year.ago.to_date)
      create_transaction!(@chase_checking, 15000, "Roof Replacement", @utilities_cat, 3.years.ago.to_date)
      create_transaction!(@chase_checking, 10000, "Family Emergency", @healthcare_cat, 4.years.ago.to_date)
      create_transaction!(@chase_checking, 18000, "Investment Property Down Payment", @travel_cat, 6.years.ago.to_date)
      create_transaction!(@chase_checking, 22000, "Second Car Purchase", @transportation_cat, 8.years.ago.to_date)
      create_transaction!(@chase_checking, 15000, "Wedding Expenses", @entertainment_cat, 9.years.ago.to_date)
      create_transaction!(@chase_checking, 8000, "Furniture & Electronics", @shopping_cat, 5.years.ago.to_date)
    end

    def generate_transfers_and_payments!
      # Deterministic credit card cycles - generate charges then payments
      generate_credit_card_cycles!

      # EUR account funding - add regular transfers to cover expenses
      20.times do
        date = weighted_random_date
        next if date < 4.years.ago.to_date # Only since account opening
        eur_amount = rand(1000..3000)
        create_transaction!(@eu_checking, -eur_amount, "EUR Transfer from USD", nil, date)
      end

      # Savings transfers (balanced)
      60.times do
        date = weighted_random_date
        amount = rand(2000..6000) # Moderate transfers
        create_transfer!(@chase_checking, @marcus_savings, amount, "Savings Transfer", date)
      end

      # Tax refunds (annual) - some to Ally to keep it positive
      12.times do |year|
        refund_date = (12 - year).years.ago.to_date + rand(60..120).days # Spring timeframe
        next if refund_date > Date.current

        refund_amount = rand(3000..8000)
        account = year.even? ? @marcus_savings : @ally_checking # Alternate accounts
        create_transaction!(account, -refund_amount, "Tax Refund", @salary_cat, refund_date)
      end

      # Major expenses from savings (realistic amounts)
      create_transaction!(@marcus_savings, 35000, "Investment Property Purchase", @travel_cat, 4.years.ago.to_date)
      create_transaction!(@marcus_savings, 25000, "Business Investment", @shopping_cat, 6.years.ago.to_date)
      create_transaction!(@marcus_savings, 20000, "Family Emergency Medical", @healthcare_cat, 8.years.ago.to_date)
      create_transaction!(@marcus_savings, 15000, "Kids College Fund", @entertainment_cat, 10.years.ago.to_date)
    end

    def generate_credit_card_cycles!
      # Generate deterministic credit card spending cycles
      # Each cycle: 5-8 charges followed by a payment that covers 70-90% of charges

      start_date = 12.years.ago.to_date
      current_amex_balance = 1500 # Starting debt
      current_sapphire_balance = 2200 # Starting debt

      # Create initial balances
      create_transaction!(@amex_gold, current_amex_balance, "Starting Balance", nil, start_date)
      create_transaction!(@chase_sapphire, current_sapphire_balance, "Starting Balance", nil, start_date)

      cycle_date = start_date + 1.month

      while cycle_date <= Date.current
        # Amex cycle (monthly)
        if cycle_date.day.between?(1, 5) # Beginning of month
          amex_charges = generate_credit_card_charges(@amex_gold, cycle_date, 5..8)
          current_amex_balance += amex_charges

          # Keep balance between $1,000 and $15,000
          if current_amex_balance > 8000 || (cycle_date.day == 15 && current_amex_balance > 3000)
            payment_percent = rand(70..90) / 100.0
            payment_amount = (amex_charges * payment_percent).round
            payment_amount = [ payment_amount, current_amex_balance - 1000 ].min # Don't overpay

            if payment_amount > 0
              create_transfer!(@chase_checking, @amex_gold, payment_amount, "Amex Payment", cycle_date + rand(15..25).days)
              current_amex_balance -= payment_amount
            end
          end
        end

        # Sapphire cycle (monthly)
        if cycle_date.day.between?(10, 15) # Mid month
          sapphire_charges = generate_credit_card_charges(@chase_sapphire, cycle_date, 4..7)
          current_sapphire_balance += sapphire_charges

          # Keep balance between $1,000 and $15,000
          if current_sapphire_balance > 6000 || (cycle_date.day == 25 && current_sapphire_balance > 2500)
            payment_percent = rand(75..95) / 100.0
            payment_amount = (sapphire_charges * payment_percent).round
            payment_amount = [ payment_amount, current_sapphire_balance - 1200 ].min # Don't overpay

            if payment_amount > 0
              create_transfer!(@chase_checking, @chase_sapphire, payment_amount, "Sapphire Payment", cycle_date + rand(20..28).days)
              current_sapphire_balance -= payment_amount
            end
          end
        end

        cycle_date += 1.month
      end

      puts "   💳 Final Amex balance: ~$#{current_amex_balance}"
      puts "   💳 Final Sapphire balance: ~$#{current_sapphire_balance}"
    end

    def generate_credit_card_charges(account, base_date, charge_count_range)
      charge_count = rand(charge_count_range)
      total_charges = 0

      # Deterministic charge amounts based on account type
      charge_amounts = if account == @amex_gold
        # Amex Gold - dining and travel rewards card
        [ 89, 156, 234, 67, 123, 178, 92, 145, 201, 76, 134, 167, 98, 112, 189 ]
      else
        # Sapphire Reserve - premium travel card
        [ 134, 267, 89, 156, 298, 178, 234, 123, 201, 145, 176, 198, 167, 134, 209 ]
      end

      charge_count.times do |i|
        charge_date = base_date + rand(0..25).days
        amount = charge_amounts[i % charge_amounts.length] + rand(-20..20) # Small variation

        # Pick appropriate merchant based on card type
        merchant = if account == @amex_gold
          [ "Local Bistro", "Whole Foods", "Starbucks", "Thai Garden", "Netflix", "Amazon" ].sample
        else
          [ "Hotel Booking", "Flight Booking", "Premium Restaurant", "Luxury Store", "Car Rental" ].sample
        end

        create_transaction!(account, amount, merchant, random_expense_category, charge_date)
        total_charges += amount
      end

      total_charges
    end

    def random_expense_category
      [ @food_cat, @entertainment_cat, @shopping_cat, @travel_cat, @transportation_cat ].sample
    end

    def create_transaction!(account, amount, name, category, date)
      # For credit cards (liabilities), positive amounts = charges (increase debt)
      # For checking accounts (assets), positive amounts = expenses (decrease balance)
      # The amount is already signed correctly by the caller
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
