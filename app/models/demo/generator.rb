class Demo::Generator
  COLORS = %w[#e99537 #4da568 #6471eb #db5a54 #df4e92 #c44fe9 #eb5429 #61c9ea #805dee #6ad28a]

  # Builds a semi-realistic mirror of what production data might look like
  def reset_and_clear_data!(family_names, require_onboarding: false)
    puts "Clearing existing data..."

    destroy_everything!

    puts "Data cleared"

    family_names.each_with_index do |family_name, index|
      create_family_and_user!(family_name, "user#{index == 0 ? "" : index + 1}@maybe.local", require_onboarding: require_onboarding)
    end

    puts "Users reset"
  end

  def reset_data!(family_names)
    puts "Clearing existing data..."

    destroy_everything!

    puts "Data cleared"

    family_names.each_with_index do |family_name, index|
      create_family_and_user!(family_name, "user#{index == 0 ? "" : index + 1}@maybe.local")
    end

    puts "Users reset"

    load_securities!

    puts "Securities loaded"

    family_names.each do |family_name|
      family = Family.find_by(name: family_name)

      ActiveRecord::Base.transaction do
        create_tags!(family)
        create_categories!(family)
        create_merchants!(family)
        create_rules!(family)
        puts "tags, categories, merchants created for #{family_name}"

        create_credit_card_account!(family)
        create_checking_account!(family)
        create_savings_account!(family)

        create_investment_account!(family)
        create_house_and_mortgage!(family)
        create_car_and_loan!(family)
        create_other_accounts!(family)

        create_transfer_transactions!(family)
      end

      puts "accounts created for #{family_name}"
    end

    puts "Demo data loaded successfully!"
  end

  def generate_basic_budget_data!(family_names)
    puts "Clearing existing data..."

    destroy_everything!

    puts "Data cleared"

    family_names.each_with_index do |family_name, index|
      create_family_and_user!(family_name, "user#{index == 0 ? "" : index + 1}@maybe.local")
    end

    puts "Users reset"

    family_names.each do |family_name|
      family = Family.find_by(name: family_name)

      ActiveRecord::Base.transaction do
        # Create parent categories
        food = family.categories.create!(name: "Food & Drink", color: COLORS.sample, classification: "expense")
        transport = family.categories.create!(name: "Transportation", color: COLORS.sample, classification: "expense")

        # Create subcategory
        restaurants = family.categories.create!(name: "Restaurants", parent: food, color: COLORS.sample, classification: "expense")

        # Create checking account
        checking = family.accounts.create!(
          accountable: Depository.new,
          name: "Demo Checking",
          balance: 3000,
          currency: "USD"
        )

        # Create one transaction for each category
        create_transaction!(account: checking, amount: 100, name: "Grocery Store", category: food, date: 2.days.ago)
        create_transaction!(account: checking, amount: 50, name: "Restaurant Meal", category: restaurants, date: 1.day.ago)
        create_transaction!(account: checking, amount: 20, name: "Gas Station", category: transport, date: Date.current)
      end

      puts "Basic budget data created for #{family_name}"
    end

    puts "Demo data loaded successfully!"
  end

  def generate_multi_currency_data!(family_names)
    puts "Clearing existing data..."

    destroy_everything!

    puts "Data cleared"

    family_names.each_with_index do |family_name, index|
      create_family_and_user!(family_name, "user#{index == 0 ? "" : index + 1}@maybe.local", currency: "EUR")
    end

    puts "Users reset"

    family_names.each do |family_name|
      puts "Generating demo data for #{family_name}"
      family = Family.find_by(name: family_name)

      usd_checking = family.accounts.create!(name: "USD Checking", currency: "USD", balance: 10000, accountable: Depository.new)
      eur_checking = family.accounts.create!(name: "EUR Checking", currency: "EUR", balance: 4900, accountable: Depository.new)
      eur_credit_card = family.accounts.create!(name: "EUR Credit Card", currency: "EUR", balance: 2300, accountable: CreditCard.new)

      create_transaction!(account: eur_credit_card, amount: 1000, currency: "EUR", name: "EUR cc expense 1")
      create_transaction!(account: eur_credit_card, amount: 1000, currency: "EUR", name: "EUR cc expense 2")
      create_transaction!(account: eur_credit_card, amount: 300, currency: "EUR", name: "EUR cc expense 3")

      create_transaction!(account: usd_checking, amount: -11000, currency: "USD", name: "USD income Transaction")
      create_transaction!(account: usd_checking, amount: 1000, currency: "USD", name: "USD expense Transaction")
      create_transaction!(account: usd_checking, amount: 1000, currency: "USD", name: "USD expense Transaction")
      create_transaction!(account: eur_checking, amount: -5000, currency: "EUR", name: "EUR income Transaction")
      create_transaction!(account: eur_checking, amount: 100, currency: "EUR", name: "EUR expense Transaction")

      puts "Transactions created for #{family_name}"
    end

    puts "Demo data loaded successfully!"
  end

  private
    def destroy_everything!
      Family.destroy_all
      Setting.destroy_all
      InviteCode.destroy_all
      ExchangeRate.destroy_all
      Security.destroy_all
      Security::Price.destroy_all
    end

    def create_family_and_user!(family_name, user_email, currency: "USD", require_onboarding: false)
      base_uuid = "d99e3c6e-d513-4452-8f24-dc263f8528c0"
      id = Digest::UUID.uuid_v5(base_uuid, family_name)

      family = Family.create!(
        id: id,
        name: family_name,
        currency: currency,
        stripe_subscription_status: require_onboarding ? nil : "active",
        locale: "en",
        country: "US",
        timezone: "America/New_York",
        date_format: "%m-%d-%Y"
      )

      family.users.create! \
        email: user_email,
        first_name: "Demo",
        last_name: "User",
        role: "admin",
        password: "password",
        onboarded_at: require_onboarding ? nil : Time.current

      family.users.create! \
        email: "member_#{user_email}",
        first_name: "Demo (member user)",
        last_name: "User",
        role: "member",
        password: "password",
        onboarded_at: require_onboarding ? nil : Time.current
    end

    def create_rules!(family)
      family.rules.create!(
        effective_date: 1.year.ago.to_date,
        active: true,
        resource_type: "transaction",
        conditions: [
          Rule::Condition.new(condition_type: "transaction_merchant", operator: "=", value: "Whole Foods")
        ],
        actions: [
          Rule::Action.new(action_type: "set_transaction_category", value: "Groceries")
        ]
      )
    end

    def create_tags!(family)
      [ "Trips", "Emergency Fund", "Demo Tag" ].each do |tag|
        family.tags.create!(name: tag)
      end
    end

    def create_categories!(family)
      family.categories.bootstrap!

      food = family.categories.find_by(name: "Food & Drink")
      family.categories.create!(name: "Restaurants", parent: food, color: COLORS.sample, lucide_icon: "utensils", classification: "expense")
      family.categories.create!(name: "Groceries", parent: food, color: COLORS.sample, lucide_icon: "shopping-cart", classification: "expense")
      family.categories.create!(name: "Alcohol & Bars", parent: food, color: COLORS.sample, lucide_icon: "beer", classification: "expense")
    end

    def create_merchants!(family)
      merchants = [ "Amazon", "Starbucks", "McDonald's", "Target", "Costco",
                   "Home Depot", "Shell", "Whole Foods", "Walgreens", "Nike",
                   "Uber", "Netflix", "Spotify", "Delta Airlines", "Airbnb", "Sephora" ]

      merchants.each do |merchant|
        FamilyMerchant.create!(name: merchant, family: family, color: COLORS.sample)
      end
    end

    def create_credit_card_account!(family)
      cc = family.accounts.create! \
        accountable: CreditCard.new,
        name: "Chase Credit Card",
        balance: 2300,
        currency: "USD"

      800.times do
        merchant = random_family_record(Merchant, family)
        create_transaction! \
          account: cc,
          name: merchant.name,
          amount: Faker::Number.positive(to: 200),
          tags: [ tag_for_merchant(merchant, family) ],
          category: category_for_merchant(merchant, family),
          merchant: merchant
      end

      24.times do
        create_transaction! \
          account: cc,
          amount: Faker::Number.negative(from: -1000),
          name: "CC Payment"
      end
    end

    def create_checking_account!(family)
      checking = family.accounts.create! \
        accountable: Depository.new,
        name: "Chase Checking",
        balance: 15000,
        currency: "USD"

      # First create income transactions to ensure positive balance
      50.times do
        create_transaction! \
          account: checking,
          amount: Faker::Number.negative(from: -2000, to: -500),
          name: "Income",
          category: family.categories.find_by(name: "Income")
      end

      # Then create expenses that won't exceed the income
      200.times do
        create_transaction! \
          account: checking,
          name: "Expense",
          amount: Faker::Number.positive(from: 8, to: 500)
      end
    end

    def create_savings_account!(family)
      savings = family.accounts.create! \
        accountable: Depository.new,
        name: "Demo Savings",
        balance: 40000,
        currency: "USD",
        subtype: "savings"

      # Create larger income deposits first
      100.times do
        create_transaction! \
          account: savings,
          amount: Faker::Number.negative(from: -3000, to: -1000),
          tags: [ family.tags.find_by(name: "Emergency Fund") ],
          category: family.categories.find_by(name: "Income"),
          name: "Income"
      end

      # Add some smaller withdrawals that won't exceed the deposits
      50.times do
        create_transaction! \
          account: savings,
          amount: Faker::Number.positive(from: 100, to: 1000),
          name: "Savings Withdrawal"
      end
    end

    def create_transfer_transactions!(family)
      checking = family.accounts.find_by(name: "Chase Checking")
      credit_card = family.accounts.find_by(name: "Chase Credit Card")
      investment = family.accounts.find_by(name: "Robinhood")

      create_transaction!(
        account: checking,
        date: 1.day.ago.to_date,
        amount: 100,
        name: "Credit Card Payment"
      )

      create_transaction!(
        account: credit_card,
        date: 1.day.ago.to_date,
        amount: -100,
        name: "Credit Card Payment"
      )

      create_transaction!(
        account: checking,
        date: 3.days.ago.to_date,
        amount: 500,
        name: "Transfer to investment"
      )

      create_transaction!(
        account: investment,
        date: 2.days.ago.to_date,
        amount: -500,
        name: "Transfer from checking"
      )
    end

    def load_securities!
      # Create an unknown security to simulate edge cases
      Security.create! ticker: "UNKNOWN", name: "Unknown Demo Stock"

      securities = [
        { ticker: "AAPL", exchange_mic: "XNGS", exchange_operating_mic: "XNAS", name: "Apple Inc.", reference_price: 210 },
        { ticker: "TM", exchange_mic: "XNYS", exchange_operating_mic: "XNYS", name: "Toyota Motor Corporation", reference_price: 202 },
        { ticker: "MSFT", exchange_mic: "XNGS", exchange_operating_mic: "XNAS", name: "Microsoft Corporation", reference_price: 455 }
      ]

      securities.each do |security_attributes|
        security = Security.create! security_attributes.except(:reference_price)

        # Load prices for last 2 years
        (730.days.ago.to_date..Date.current).each do |date|
          reference = security_attributes[:reference_price]
          low_price = reference - 20
          high_price = reference + 20
          Security::Price.create! \
            security: security,
            date: date,
            price: Faker::Number.positive(from: low_price, to: high_price)
        end
      end
    end

    def create_investment_account!(family)
      account = family.accounts.create! \
        accountable: Investment.new,
        name: "Robinhood",
        balance: 100000,
        currency: "USD"

      aapl = Security.find_by(ticker: "AAPL")
      tm = Security.find_by(ticker: "TM")
      msft = Security.find_by(ticker: "MSFT")
      unknown = Security.find_by(ticker: "UNKNOWN")

      # Buy 20 shares of the unknown stock to simulate a stock where we can't fetch security prices
      account.entries.create! date: 10.days.ago.to_date, amount: 100, currency: "USD", name: "Buy unknown stock", entryable: Trade.new(qty: 20, price: 5, security: unknown, currency: "USD")

      trades = [
        { security: aapl, qty: 20 }, { security: msft, qty: 10 }, { security: aapl, qty: -5 },
        { security: msft, qty: -5 }, { security: tm, qty: 10 }, { security: msft, qty: 5 },
        { security: tm, qty: 10 }, { security: aapl, qty: -5 }, { security: msft, qty: -5 },
        { security: tm, qty: 10 }, { security: msft, qty: 5 }, { security: aapl, qty: -10 }
      ]

      trades.each do |trade|
        date = Faker::Number.positive(to: 730).days.ago.to_date
        security = trade[:security]
        qty = trade[:qty]
        price = Security::Price.find_by(security: security, date: date)&.price || 1
        name_prefix = qty < 0 ? "Sell " : "Buy "

        account.entries.create! \
          date: date,
          amount: qty * price,
          currency: "USD",
          name: name_prefix + "#{qty} shares of #{security.ticker}",
          entryable: Trade.new(qty: qty, price: price, currency: "USD", security: security)
      end
    end

    def create_house_and_mortgage!(family)
      house = family.accounts.create! \
        accountable: Property.new,
        name: "123 Maybe Way",
        balance: 560000,
        currency: "USD"

      create_valuation!(house, 3.years.ago.to_date, 520000)
      create_valuation!(house, 2.years.ago.to_date, 540000)
      create_valuation!(house, 1.years.ago.to_date, 550000)

      mortgage = family.accounts.create! \
        accountable: Loan.new,
        name: "Mortgage",
        balance: 495000,
        currency: "USD"

      create_valuation!(mortgage, 3.years.ago.to_date, 495000)
      create_valuation!(mortgage, 2.years.ago.to_date, 490000)
      create_valuation!(mortgage, 1.years.ago.to_date, 485000)
    end

    def create_car_and_loan!(family)
      vehicle = family.accounts.create! \
        accountable: Vehicle.new,
        name: "Honda Accord",
        balance: 18000,
        currency: "USD"

      create_valuation!(vehicle, 1.year.ago.to_date, 18000)

      loan = family.accounts.create! \
        accountable: Loan.new,
        name: "Car Loan",
        balance: 8000,
        currency: "USD"

      create_valuation!(loan, 1.year.ago.to_date, 8000)
    end

    def create_other_accounts!(family)
      other_asset = family.accounts.create! \
        accountable: OtherAsset.new,
        name: "Other Asset",
        balance: 10000,
        currency: "USD"

      other_liability = family.accounts.create! \
        accountable: OtherLiability.new,
        name: "Other Liability",
        balance: 5000,
        currency: "USD"

      create_valuation!(other_asset, 1.year.ago.to_date, 10000)
      create_valuation!(other_liability, 1.year.ago.to_date, 5000)
    end

    def create_transaction!(attributes = {})
      entry_attributes = attributes.except(:category, :tags, :merchant)
      transaction_attributes = attributes.slice(:category, :tags, :merchant)

      entry_defaults = {
        date: Faker::Number.between(from: 0, to: 730).days.ago.to_date,
        currency: "USD",
        entryable: Transaction.new(transaction_attributes)
      }

      Entry.create! entry_defaults.merge(entry_attributes)
    end

    def create_valuation!(account, date, amount)
      Entry.create! \
        account: account,
        date: date,
        amount: amount,
        currency: "USD",
        name: "Balance update",
        entryable: Valuation.new
    end

    def random_family_record(model, family)
      family_records = model.where(family_id: family.id)
      model.offset(rand(family_records.count)).first
    end

    def category_for_merchant(merchant, family)
      mapping = {
        "Amazon" => "Shopping",
        "Starbucks" => "Food & Drink",
        "McDonald's" => "Food & Drink",
        "Target" => "Shopping",
        "Costco" => "Food & Drink",
        "Home Depot" => "Housing",
        "Shell" => "Transportation",
        "Whole Foods" => "Food & Drink",
        "Walgreens" => "Healthcare",
        "Nike" => "Shopping",
        "Uber" => "Transportation",
        "Netflix" => "Subscriptions",
        "Spotify" => "Subscriptions",
        "Delta Airlines" => "Transportation",
        "Airbnb" => "Housing",
        "Sephora" => "Shopping"
      }

      family.categories.find_by(name: mapping[merchant.name])
    end

    def tag_for_merchant(merchant, family)
      mapping = {
        "Delta Airlines" => "Trips",
        "Airbnb" => "Trips"
      }

      tag_from_merchant = family.tags.find_by(name: mapping[merchant.name])
      tag_from_merchant || family.tags.find_by(name: "Demo Tag")
    end

    def securities
      @securities ||= Security.all.to_a
    end
end
