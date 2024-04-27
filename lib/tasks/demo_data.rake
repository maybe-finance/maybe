namespace :demo_data do
  desc "Creates or resets demo data used in development environment"
  task reset: :environment do
    family = Family.find_or_create_by(name: "Demo Family")

    family.accounts.delete_all
    ExchangeRate.delete_all
    family.transaction_categories.delete_all
    Transaction::Category.create_default_categories(family)

    user = User.find_or_create_by(email: "user@maybe.local") do |u|
      u.password = "password"
      u.family = family
      u.first_name = "User"
      u.last_name = "Demo"
      u.marked_for_deletion = false # if existing user found
    end

    puts "Reset user: #{user.email} with family: #{family.name}"

    # Mock exchange rates for last 60 days (these rates are reasonable for EUR:USD, but not exact)
    exchange_rates = (0..60).map do |days_ago|
      {
        date: Date.current - days_ago.days,
        base_currency: "EUR",
        converted_currency: "USD",
        rate: rand(1.0840..1.0924).round(4)
      }
    end

    exchange_rates += (0..20).map do |days_ago|
      {
        date: Date.current - days_ago.days,
        base_currency: "BTC",
        converted_currency: "USD",
        rate: rand(60000..65000).round(2)
      }
    end

    # Multi-currency account needs a few USD:EUR rates
    exchange_rates += [
      { date: Date.current - 45.days, base_currency: "USD", converted_currency: "EUR", rate: 0.89 },
      { date: Date.current - 34.days, base_currency: "USD", converted_currency: "EUR", rate: 0.87 },
      { date: Date.current - 28.days, base_currency: "USD", converted_currency: "EUR", rate: 0.88 },
      { date: Date.current - 14.days, base_currency: "USD", converted_currency: "EUR", rate: 0.86 }
    ]

    ExchangeRate.insert_all(exchange_rates)

    puts "Loaded mock exchange rates for last 60 days"

    # ========== Accounts ================
    empty_account = Account.create(name: "Demo Empty Account", family: family, accountable: Account::Depository.new, balance: 500, currency: "USD")
    multi_currency_checking = Account.create(name: "Demo Multi-Currency Checking", family: family, accountable: Account::Depository.new, balance: 4000, currency: "EUR")
    checking = Account.create(name: "Demo Checking", family: family, accountable: Account::Depository.new, balance: 5000, currency: "USD")
    savings = Account.create(name: "Demo Savings", family: family, accountable: Account::Depository.new, balance: 20000, currency: "USD")
    credit_card = Account.create(name: "Demo Credit Card", family: family, accountable: Account::Credit.new, balance: 1500, currency: "USD")
    retirement = Account.create(name: "Demo 401k", family: family, accountable: Account::Investment.new, balance: 100000, currency: "USD")
    euro_savings = Account.create(name: "Demo Euro Savings", family: family, accountable: Account::Depository.new, balance: 10000, currency: "EUR")
    brokerage = Account.create(name: "Demo Brokerage Account", family: family, accountable: Account::Investment.new, balance: 10000, currency: "USD")
    crypto = Account.create(name: "Bitcoin Account", family: family, accountable: Account::Crypto.new, balance: 0.1, currency: "BTC")
    mortgage = Account.create(name: "Demo Mortgage", family: family, accountable: Account::Loan.new, balance: 450000, currency: "USD")
    main_car = Account.create(name: "Demo Main Car", family: family, accountable: Account::Vehicle.new, balance: 25000, currency: "USD")
    cash = Account.create(name: "Demo Physical Cash", family: family, accountable: Account::OtherAsset.new, balance: 500, currency: "USD")
    car_loan = Account.create(name: "Demo Car Loan", family: family, accountable: Account::Loan.new, balance: 10000, currency: "USD")
    house = Account.create(name: "Demo Primary Residence", family: family, accountable: Account::Property.new, balance: 2500000, currency: "USD")
    personal_iou = Account.create(name: "Demo Personal IOU", family: family, accountable: Account::OtherLiability.new, balance: 1000, currency: "USD")
    second_car = Account.create(name: "Demo Secondary Car", family: family, accountable: Account::Vehicle.new, balance: 12000, currency: "USD")


    # ========== Transactions ================
    multi_currency_checking_transactions = [
      { date: Date.today - 45, amount: 3000, name: "Paycheck", currency: "USD" },
      { date: Date.today - 41, amount: -1500, name: "Rent Payment", currency: "EUR" },
      { date: Date.today - 39, amount: -200, name: "Groceries", currency: "EUR" },
      { date: Date.today - 34, amount: 3000, name: "Paycheck", currency: "USD" },
      { date: Date.today - 31, amount: -1500, name: "Rent Payment", currency: "EUR" },
      { date: Date.today - 28, amount: -100, name: "Utilities", currency: "EUR" },
      { date: Date.today - 28, amount: 3000, name: "Paycheck", currency: "USD" },
      { date: Date.today - 28, amount: -1500, name: "Rent Payment", currency: "EUR" },
      { date: Date.today - 28, amount: -50, name: "Internet Bill", currency: "EUR" },
      { date: Date.today - 14, amount: 3000, name: "Paycheck", currency: "USD" }
    ]

    checking_transactions = [
      { date: Date.today - 84, amount: -3000, name: "Direct Deposit" },
      { date: Date.today - 70, amount: 1500, name: "Credit Card Payment" },
      { date: Date.today - 70, amount: 200, name: "Utility Bill" },
      { date: Date.today - 56, amount: -3000, name: "Direct Deposit" },
      { date: Date.today - 42, amount: 1500, name: "Credit Card Payment" },
      { date: Date.today - 42, amount: 100, name: "Internet Bill" },
      { date: Date.today - 28, amount: -3000, name: "Direct Deposit" },
      { date: Date.today - 28, amount: 1500, name: "Credit Card Payment" },
      { date: Date.today - 28, amount: 50, name: "Mobile Bill" },
      { date: Date.today - 14, amount: -3000, name: "Direct Deposit" },
      { date: Date.today - 14, amount: 1500, name: "Credit Card Payment" },
      { date: Date.today - 14, amount: 200, name: "Car Loan Payment" },
      { date: Date.today - 7, amount: 150, name: "Insurance" },
      { date: Date.today - 2, amount: 100, name: "Gym Membership" }
    ]

    savings_transactions = [
      { date: Date.today - 360, amount: -1000, name: "Initial Deposit" },
      { date: Date.today - 330, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 300, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 270, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 240, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 210, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 180, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 150, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 120, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 90, amount: 1000, name: "Withdrawal" },
      { date: Date.today - 60, amount: -200, name: "Monthly Savings" },
      { date: Date.today - 30, amount: -200, name: "Monthly Savings" }
    ]

    euro_savings_transactions = [
      { date: Date.today - 55, amount: -500, name: "Initial Deposit", currency: "EUR" },
      { date: Date.today - 40, amount: -100, name: "Savings", currency: "EUR" },
      { date: Date.today - 15, amount: -100, name: "Savings", currency: "EUR" },
      { date: Date.today - 10, amount: -100, name: "Savings", currency: "EUR" },
      { date: Date.today - 9, amount: 500, name: "Withdrawal", currency: "EUR" },
      { date: Date.today - 5, amount: -100, name: "Savings", currency: "EUR" },
      { date: Date.today - 2, amount: -100, name: "Savings", currency: "EUR" }
    ]

    credit_card_transactions = [
      { date: Date.today - 90, amount: 75, name: "Grocery Store" },
      { date: Date.today - 89, amount: 30, name: "Gas Station" },
      { date: Date.today - 88, amount: 12, name: "Coffee Shop" },
      { date: Date.today - 85, amount: 50, name: "Restaurant" },
      { date: Date.today - 84, amount: 25, name: "Online Subscription" },
      { date: Date.today - 82, amount: 100, name: "Clothing Store" },
      { date: Date.today - 80, amount: 60, name: "Pharmacy" },
      { date: Date.today - 78, amount: 40, name: "Utility Bill" },
      { date: Date.today - 75, amount: 90, name: "Home Improvement Store" },
      { date: Date.today - 74, amount: 20, name: "Book Store" },
      { date: Date.today - 72, amount: 15, name: "Movie Theater" },
      { date: Date.today - 70, amount: 200, name: "Electronics Store" },
      { date: Date.today - 68, amount: 35, name: "Pet Store" },
      { date: Date.today - 65, amount: 80, name: "Sporting Goods Store" },
      { date: Date.today - 63, amount: 55, name: "Department Store" },
      { date: Date.today - 60, amount: 110, name: "Auto Repair Shop" },
      { date: Date.today - 58, amount: 45, name: "Beauty Salon" },
      { date: Date.today - 55, amount: 95, name: "Furniture Store" },
      { date: Date.today - 53, amount: 22, name: "Fast Food" },
      { date: Date.today - 50, amount: 120, name: "Airline Ticket" },
      { date: Date.today - 48, amount: 65, name: "Hotel" },
      { date: Date.today - 45, amount: 30, name: "Car Rental" },
      { date: Date.today - 43, amount: 18, name: "Music Store" },
      { date: Date.today - 40, amount: 70, name: "Grocery Store" },
      { date: Date.today - 38, amount: 32, name: "Gas Station" },
      { date: Date.today - 36, amount: 14, name: "Coffee Shop" },
      { date: Date.today - 33, amount: 52, name: "Restaurant" },
      { date: Date.today - 31, amount: 28, name: "Online Subscription" },
      { date: Date.today - 29, amount: 105, name: "Clothing Store" },
      { date: Date.today - 27, amount: 62, name: "Pharmacy" },
      { date: Date.today - 25, amount: 42, name: "Utility Bill" },
      { date: Date.today - 22, amount: 92, name: "Home Improvement Store" },
      { date: Date.today - 20, amount: 23, name: "Book Store" },
      { date: Date.today - 18, amount: 17, name: "Movie Theater" },
      { date: Date.today - 15, amount: 205, name: "Electronics Store" },
      { date: Date.today - 13, amount: 37, name: "Pet Store" },
      { date: Date.today - 10, amount: 83, name: "Sporting Goods Store" },
      { date: Date.today - 8, amount: 57, name: "Department Store" },
      { date: Date.today - 5, amount: 115, name: "Auto Repair Shop" },
      { date: Date.today - 3, amount: 47, name: "Beauty Salon" },
      { date: Date.today - 1, amount: 98, name: "Furniture Store" },
      { date: Date.today - 60, amount: -800, name: "Credit Card Payment" },
      { date: Date.today - 30, amount: -900, name: "Credit Card Payment" },
      { date: Date.today, amount: -1000, name: "Credit Card Payment" }
    ]

    mortgage_transactions = [
      { date: Date.today - 90, amount: -1500, name: "Mortgage Payment" },
      { date: Date.today - 60, amount: -1500, name: "Mortgage Payment" },
      { date: Date.today - 30, amount: -1500, name: "Mortgage Payment" }
    ]

    car_loan_transactions = [
      { date: 12.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 11.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 10.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 9.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 8.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 7.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 6.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 5.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 4.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 3.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 2.months.ago.to_date, amount: -1250, name: "Car Loan Payment" },
      { date: 1.month.ago.to_date, amount: -1250, name: "Car Loan Payment" }
    ]

    # ========== Valuations ================
    retirement_valuations = [
      { date: 1.year.ago.to_date, value: 90000 },
      { date: 200.days.ago.to_date, value: 95000 },
      { date: 100.days.ago.to_date, value: 94444.96 },
      { date: 20.days.ago.to_date, value: 100000 }
    ]

    brokerage_valuations = [
      { date: 1.year.ago.to_date, value: 9000 },
      { date: 200.days.ago.to_date, value: 9500 },
      { date: 100.days.ago.to_date, value: 9444.96 },
      { date: 20.days.ago.to_date, value: 10000 }
    ]

    crypto_valuations = [
      { date: 1.week.ago.to_date, value: 0.08, currency: "BTC" },
      { date: 2.days.ago.to_date, value: 0.1, currency: "BTC" }
    ]

    mortgage_valuations = [
      { date: 2.years.ago.to_date, value: 500000 },
      { date: 6.months.ago.to_date, value: 455000 }
    ]

    house_valuations = [
      { date: 5.years.ago.to_date, value: 3000000 },
      { date: 4.years.ago.to_date, value: 2800000 },
      { date: 3.years.ago.to_date, value: 2700000 },
      { date: 2.years.ago.to_date, value: 2600000 },
      { date: 1.year.ago.to_date, value: 2500000 }
    ]

    main_car_valuations = [
      { date: 1.year.ago.to_date, value: 25000 }
    ]

    second_car_valuations = [
      { date: 2.years.ago.to_date, value: 11000 },
      { date: 1.year.ago.to_date, value: 12000 }
    ]

    cash_valuations = [
      { date: 1.month.ago.to_date, value: 500 }
    ]

    personal_iou_valuations = [
      { date: 1.month.ago.to_date, value: 1000 }
    ]

    # Insert valuations
    retirement.valuations.insert_all(retirement_valuations)
    brokerage.valuations.insert_all(brokerage_valuations)
    crypto.valuations.insert_all(crypto_valuations)
    mortgage.valuations.insert_all(mortgage_valuations)
    house.valuations.insert_all(house_valuations)
    main_car.valuations.insert_all(main_car_valuations)
    second_car.valuations.insert_all(second_car_valuations)
    cash.valuations.insert_all(cash_valuations)
    personal_iou.valuations.insert_all(personal_iou_valuations)

    # Insert transactions
    multi_currency_checking.transactions.insert_all(multi_currency_checking_transactions)
    checking.transactions.insert_all(checking_transactions)
    savings.transactions.insert_all(savings_transactions)
    euro_savings.transactions.insert_all(euro_savings_transactions)
    credit_card.transactions.insert_all(credit_card_transactions)
    mortgage.transactions.insert_all(mortgage_transactions)
    car_loan.transactions.insert_all(car_loan_transactions)

    puts "Created demo accounts, transactions, and valuations for family: #{family.name}"

    puts "Syncing accounts...  This may take a few seconds."

    family.accounts.each do |account|
      account.sync
    end

    puts "Accounts synced.  Demo data reset complete."
  end
end
