namespace :demo_data do
  desc "Creates or resets demo data used in development environment"
  task reset: :environment do
    family = Family.find_or_create_by(name: "Demo Family")

    family.accounts.destroy_all

    user = User.find_or_create_by(email: "user@maybe.local") do |u|
      u.password = "password"
      u.family = family
      u.first_name = "User"
      u.last_name = "Demo"
    end

    puts "Reset user: #{user.email} with family: #{family.name}"

    Transaction::Category.create_default_categories(family) if family.transaction_categories.empty?

    # No historical data for this account
    empty_account = Account.find_or_create_by(name: "Demo Empty Account") do |a|
      a.family = family
      a.accountable = Account::Depository.new
      a.balance = 500
      a.currency = "USD"
    end

    multi_currency_checking = Account.find_or_create_by(name: "Demo Multi-Currency Checking") do |a|
      a.family = family
      a.accountable = Account::Depository.new
      a.balance = 4000
      a.currency = "EUR"
    end

    multi_currency_checking_transactions = [
      { date: Date.today - 84, amount: 3000, name: "Paycheck", currency: "USD" },
      { date: Date.today - 70, amount: -1500, name: "Rent Payment", currency: "EUR" },
      { date: Date.today - 70, amount: -200, name: "Groceries", currency: "EUR" },
      { date: Date.today - 56, amount: 3000, name: "Paycheck", currency: "USD" },
      { date: Date.today - 42, amount: -1500, name: "Rent Payment", currency: "EUR" },
      { date: Date.today - 42, amount: -100, name: "Utilities", currency: "EUR" },
      { date: Date.today - 28, amount: 3000, name: "Paycheck", currency: "USD" },
      { date: Date.today - 28, amount: -1500, name: "Rent Payment", currency: "EUR" },
      { date: Date.today - 28, amount: -50, name: "Internet Bill", currency: "EUR" },
      { date: Date.today - 14, amount: 3000, name: "Paycheck", currency: "USD" }
    ]

    multi_currency_checking_transactions.each do |t|
      multi_currency_checking.transactions.find_or_create_by(date: t[:date], amount: t[:amount], name: t[:name], currency: t[:currency])
    end

    multi_currency_checking.sync

    checking = Account.find_or_create_by(name: "Demo Checking") do |a|
      a.family = family
      a.accountable = Account::Depository.new
      a.balance = 5000
    end

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

    checking_transactions.each do |t|
      checking.transactions.find_or_create_by(date: t[:date], amount: t[:amount], name: t[:name])
    end

    checking.sync

    savings = Account.find_or_create_by(name: "Demo Savings") do |a|
      a.family = family
      a.accountable = Account::Depository.new
      a.balance = 20000
    end

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

    savings_transactions.each do |t|
      savings.transactions.find_or_create_by(date: t[:date], amount: t[:amount], name: t[:name])
    end

    savings.sync

    euro_savings = Account.find_or_create_by(name: "Demo Euro Savings") do |a|
      a.family = family
      a.accountable = Account::Depository.new
      a.balance = 10000
      a.currency = "EUR"
    end

    euro_savings_transactions = [
      { date: Date.today - 360, amount: -500, name: "Initial Deposit", currency: "EUR" },
      { date: Date.today - 330, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 300, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 270, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 240, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 210, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 180, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 150, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 120, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 90, amount: 500, name: "Withdrawal", currency: "EUR" },
      { date: Date.today - 60, amount: -100, name: "Monthly Savings", currency: "EUR" },
      { date: Date.today - 30, amount: -100, name: "Monthly Savings", currency: "EUR" }
    ]

    euro_savings_transactions.each do |t|
      euro_savings.transactions.find_or_create_by(date: t[:date], amount: t[:amount], name: t[:name], currency: t[:currency])
    end

    euro_savings.sync

    credit_card = Account.find_or_create_by(name: "Demo Credit Card") do |a|
      a.family = family
      a.accountable = Account::Credit.new
      a.balance = 1500
    end

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

    credit_card_transactions.each do |t|
      credit_card.transactions.find_or_create_by(date: t[:date], amount: t[:amount], name: t[:name])
    end

    credit_card.sync

    retirement = Account.find_or_create_by(name: "Demo 401k") do |a|
      a.family = family
      a.accountable = Account::Investment.new
      a.balance = 100000
    end

    retirement_valuations = [
      { date: 1.year.ago.to_date, value: 90000 },
      { date: 200.days.ago.to_date, value: 95000 },
      { date: 100.days.ago.to_date, value: 94444.96 },
      { date: 20.days.ago.to_date, value: 100000 }
    ]

    retirement.valuations.upsert_all(retirement_valuations, unique_by: :index_valuations_on_account_id_and_date)

    retirement.sync

    brokerage = Account.find_or_create_by(name: "Demo Brokerage Account") do |a|
      a.family = family
      a.accountable = Account::Investment.new
      a.balance = 10000
    end

    brokerage_valuations = [
      { date: 1.year.ago.to_date, value: 9000 },
      { date: 200.days.ago.to_date, value: 9500 },
      { date: 100.days.ago.to_date, value: 9444.96 },
      { date: 20.days.ago.to_date, value: 10000 }
    ]

    brokerage.valuations.upsert_all(brokerage_valuations, unique_by: :index_valuations_on_account_id_and_date)

    brokerage.sync

    crypto = Account.find_or_create_by(name: "Bitcoin Account") do |a|
      a.family = family
      a.accountable = Account::Crypto.new
      a.currency = "BTC"
      a.balance = 0.1
      end

    crypto_valuations = [
    { date: 1.year.ago.to_date, value: 0.05, currency: "BTC" },
    { date: 200.days.ago.to_date, value: 0.06, currency: "BTC" },
    { date: 100.days.ago.to_date, value: 0.08, currency: "BTC" },
    { date: 20.days.ago.to_date, value: 0.1, currency: "BTC" }
    ]

    crypto.valuations.upsert_all(crypto_valuations, unique_by: :index_valuations_on_account_id_and_date)

    crypto.sync

    mortgage = Account.find_or_create_by(name: "Demo Mortgage") do |a|
      a.family = family
      a.accountable = Account::Loan.new
      a.balance = 450000
    end

    mortgage_transactions = [
      { date: Date.today - 90, amount: -1500, name: "Mortgage Payment" },
      { date: Date.today - 60, amount: -1500, name: "Mortgage Payment" },
      { date: Date.today - 30, amount: -1500, name: "Mortgage Payment" }
    ]

    mortgage_transactions.each do |t|
      mortgage.transactions.find_or_create_by(date: t[:date], amount: t[:amount], name: t[:name])
    end

    mortgage_valuations = [
      { date: 2.years.ago.to_date, value: 500000 },
      { date: 6.months.ago.to_date, value: 455000 }
    ]

    mortgage.valuations.upsert_all(mortgage_valuations, unique_by: :index_valuations_on_account_id_and_date)

    mortgage.sync

    car_loan = Account.find_or_create_by(name: "Demo Car Loan") do |a|
      a.family = family
      a.accountable = Account::Loan.new
      a.balance = 10000
    end

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

    car_loan_transactions.each do |t|
      car_loan.transactions.find_or_create_by(date: t[:date], amount: t[:amount], name: t[:name])
    end

    car_loan.sync

    house = Account.find_or_create_by(name: "Demo Primary Residence") do |a|
      a.family = family
      a.accountable = Account::Property.new
      a.balance = 2500000
    end

    house_valuations = [
      { date: 5.years.ago.to_date, value: 3000000 },
      { date: 4.years.ago.to_date, value: 2800000 },
      { date: 3.years.ago.to_date, value: 2700000 },
      { date: 2.years.ago.to_date, value: 2600000 },
      { date: 1.year.ago.to_date, value: 2500000 }
    ]

    house.valuations.upsert_all(house_valuations, unique_by: :index_valuations_on_account_id_and_date)

    house.sync

    main_car = Account.find_or_create_by(name: "Demo Main Car") do |a|
      a.family = family
      a.accountable = Account::Vehicle.new
      a.balance = 25000
    end

    main_car_valuations = [
      { date: 1.year.ago.to_date, value: 25000 }
    ]

    main_car.valuations.upsert_all(main_car_valuations, unique_by: :index_valuations_on_account_id_and_date)

    main_car.sync

    second_car = Account.find_or_create_by(name: "Demo Secondary Car") do |a|
      a.family = family
      a.accountable = Account::Vehicle.new
      a.balance = 12000
    end

    second_car_valuations = [
      { date: 2.years.ago.to_date, value: 11000 },
      { date: 1.year.ago.to_date, value: 12000 }
    ]

    second_car.valuations.upsert_all(second_car_valuations, unique_by: :index_valuations_on_account_id_and_date)

    second_car.sync

    cash = Account.find_or_create_by(name: "Demo Physical Cash") do |a|
      a.family = family
      a.accountable = Account::OtherAsset.new
      a.balance =  500
    end

    cash_valuations = [
      { date: 1.month.ago.to_date, value: 500 }
    ]

    cash.valuations.upsert_all(cash_valuations, unique_by: :index_valuations_on_account_id_and_date)

    cash.sync

    personal_iou = Account.find_or_create_by(name: "Demo Personal IOU") do |a|
      a.family = family
      a.accountable = Account::OtherLiability.new
      a.balance =  1000
    end

    personal_iou_valuations = [
      { date: 1.month.ago.to_date, value: 1000 }
    ]

    personal_iou.valuations.upsert_all(personal_iou_valuations, unique_by: :index_valuations_on_account_id_and_date)

    personal_iou.sync

    # Just a few exchange rates for demo purposes to get started
    exchange_rates = [
      { date: "2024-03-11", base_currency: "USD", converted_currency: "EUR", rate: 0.9152 },
      { date: "2024-03-08", base_currency: "USD", converted_currency: "EUR", rate: 0.9141 },
      { date: "2024-03-07", base_currency: "USD", converted_currency: "EUR", rate: 0.9133 },
      { date: "2024-03-06", base_currency: "USD", converted_currency: "EUR", rate: 0.9176 },
      { date: "2024-03-05", base_currency: "USD", converted_currency: "EUR", rate: 0.9209 },
      { date: "2024-03-04", base_currency: "USD", converted_currency: "EUR", rate: 0.9212 },
      { date: "2024-03-01", base_currency: "USD", converted_currency: "EUR", rate: 0.9224 },
      { date: "2024-02-29", base_currency: "USD", converted_currency: "EUR", rate: 0.9254 },
      { date: "2024-02-28", base_currency: "USD", converted_currency: "EUR", rate: 0.9225 },
      { date: "2024-02-27", base_currency: "USD", converted_currency: "EUR", rate: 0.9220 },
      { date: "2024-02-26", base_currency: "USD", converted_currency: "EUR", rate: 0.9214 },
      { date: "2024-02-23", base_currency: "USD", converted_currency: "EUR", rate: 0.9240 },
      { date: "2024-02-22", base_currency: "USD", converted_currency: "EUR", rate: 0.9238 },
      { date: "2024-02-21", base_currency: "USD", converted_currency: "EUR", rate: 0.9243 },
      { date: "2024-02-20", base_currency: "USD", converted_currency: "EUR", rate: 0.9252 },
      { date: "2024-02-19", base_currency: "USD", converted_currency: "EUR", rate: 0.9275 },
      { date: "2024-02-16", base_currency: "USD", converted_currency: "EUR", rate: 0.9278 },
      { date: "2024-02-15", base_currency: "USD", converted_currency: "EUR", rate: 0.9282 },
      { date: "2024-02-14", base_currency: "USD", converted_currency: "EUR", rate: 0.9322 },
      { date: "2024-02-13", base_currency: "USD", converted_currency: "EUR", rate: 0.9338 },
      { date: "2024-02-12", base_currency: "USD", converted_currency: "EUR", rate: 0.9283 },
      { date: "2024-02-09", base_currency: "USD", converted_currency: "EUR", rate: 0.9273 },
      { date: "2024-02-08", base_currency: "USD", converted_currency: "EUR", rate: 0.9278 },
      { date: "2024-02-07", base_currency: "USD", converted_currency: "EUR", rate: 0.9282 },
      { date: "2024-02-06", base_currency: "USD", converted_currency: "EUR", rate: 0.9298 },
      { date: "2024-02-05", base_currency: "USD", converted_currency: "EUR", rate: 0.9308 },
      { date: "2024-02-02", base_currency: "USD", converted_currency: "EUR", rate: 0.9270 },
      { date: "2024-02-01", base_currency: "USD", converted_currency: "EUR", rate: 0.9198 },
      { date: "2024-01-31", base_currency: "USD", converted_currency: "EUR", rate: 0.9243 },
      { date: "2024-01-30", base_currency: "USD", converted_currency: "EUR", rate: 0.9221 },
      { date: "2024-01-29", base_currency: "USD", converted_currency: "EUR", rate: 0.9231 },
      { date: "2024-03-11", base_currency: "EUR", converted_currency: "USD", rate: 1.0926 },
      { date: "2024-03-08", base_currency: "EUR", converted_currency: "USD", rate: 1.0940 },
      { date: "2024-03-07", base_currency: "EUR", converted_currency: "USD", rate: 1.0950 },
      { date: "2024-03-06", base_currency: "EUR", converted_currency: "USD", rate: 1.0898 },
      { date: "2024-03-05", base_currency: "EUR", converted_currency: "USD", rate: 1.0858 },
      { date: "2024-03-04", base_currency: "EUR", converted_currency: "USD", rate: 1.0856 },
      { date: "2024-03-01", base_currency: "EUR", converted_currency: "USD", rate: 1.0840 },
      { date: "2024-02-29", base_currency: "EUR", converted_currency: "USD", rate: 1.0807 },
      { date: "2024-02-28", base_currency: "EUR", converted_currency: "USD", rate: 1.0839 },
      { date: "2024-02-27", base_currency: "EUR", converted_currency: "USD", rate: 1.0845 },
      { date: "2024-02-26", base_currency: "EUR", converted_currency: "USD", rate: 1.0854 },
      { date: "2024-02-23", base_currency: "EUR", converted_currency: "USD", rate: 1.0822 },
      { date: "2024-02-22", base_currency: "EUR", converted_currency: "USD", rate: 1.0824 },
      { date: "2024-02-21", base_currency: "EUR", converted_currency: "USD", rate: 1.0818 },
      { date: "2024-02-20", base_currency: "EUR", converted_currency: "USD", rate: 1.0809 },
      { date: "2024-02-19", base_currency: "EUR", converted_currency: "USD", rate: 1.0780 },
      { date: "2024-02-16", base_currency: "EUR", converted_currency: "USD", rate: 1.0778 },
      { date: "2024-02-15", base_currency: "EUR", converted_currency: "USD", rate: 1.0773 },
      { date: "2024-02-14", base_currency: "EUR", converted_currency: "USD", rate: 1.0729 },
      { date: "2024-02-13", base_currency: "EUR", converted_currency: "USD", rate: 1.0709 },
      { date: "2024-02-12", base_currency: "EUR", converted_currency: "USD", rate: 1.0773 },
      { date: "2024-02-09", base_currency: "EUR", converted_currency: "USD", rate: 1.0783 },
      { date: "2024-02-08", base_currency: "EUR", converted_currency: "USD", rate: 1.0778 },
      { date: "2024-02-07", base_currency: "EUR", converted_currency: "USD", rate: 1.0774 },
      { date: "2024-02-06", base_currency: "EUR", converted_currency: "USD", rate: 1.0755 },
      { date: "2024-02-05", base_currency: "EUR", converted_currency: "USD", rate: 1.0743 },
      { date: "2024-02-02", base_currency: "EUR", converted_currency: "USD", rate: 1.0788 },
      { date: "2024-02-01", base_currency: "EUR", converted_currency: "USD", rate: 1.0872 },
      { date: "2024-01-31", base_currency: "EUR", converted_currency: "USD", rate: 1.0819 },
      { date: "2024-01-30", base_currency: "EUR", converted_currency: "USD", rate: 1.0845 },
      { date: "2024-01-29", base_currency: "EUR", converted_currency: "USD", rate: 1.0834 },
      { date: "2024-01-26", base_currency: "EUR", converted_currency: "USD", rate: 1.0855 },
      { date: "2024-01-25", base_currency: "EUR", converted_currency: "USD", rate: 1.0849 },
      { date: "2024-01-24", base_currency: "EUR", converted_currency: "USD", rate: 1.0886 },
      { date: "2024-01-23", base_currency: "EUR", converted_currency: "USD", rate: 1.0855 },
      { date: "2024-01-22", base_currency: "EUR", converted_currency: "USD", rate: 1.0884 },
      { date: "2024-01-19", base_currency: "EUR", converted_currency: "USD", rate: 1.0897 },
      { date: "2024-01-18", base_currency: "EUR", converted_currency: "USD", rate: 1.0877 },
      { date: "2024-01-17", base_currency: "EUR", converted_currency: "USD", rate: 1.0883 },
      { date: "2024-01-16", base_currency: "EUR", converted_currency: "USD", rate: 1.0878 },
      { date: "2024-01-15", base_currency: "EUR", converted_currency: "USD", rate: 1.0953 },
      { date: "2024-01-12", base_currency: "EUR", converted_currency: "USD", rate: 1.0951 },
      { date: "2024-01-11", base_currency: "EUR", converted_currency: "USD", rate: 1.0972 },
      { date: "2024-01-10", base_currency: "EUR", converted_currency: "USD", rate: 1.0975 },
      { date: "2024-01-09", base_currency: "EUR", converted_currency: "USD", rate: 1.0933 },
      { date: "2024-01-08", base_currency: "EUR", converted_currency: "USD", rate: 1.0952 },
      { date: "2024-01-05", base_currency: "EUR", converted_currency: "USD", rate: 1.0939 },
      { date: "2024-01-04", base_currency: "EUR", converted_currency: "USD", rate: 1.0946 },
      { date: "2024-01-03", base_currency: "EUR", converted_currency: "USD", rate: 1.0922 },
      { date: "2024-01-02", base_currency: "EUR", converted_currency: "USD", rate: 1.0940 },
      { date: "2024-01-01", base_currency: "EUR", converted_currency: "USD", rate: 1.1047 },
      { date: "2023-12-29", base_currency: "EUR", converted_currency: "USD", rate: 1.1038 },
      { date: "2023-12-28", base_currency: "EUR", converted_currency: "USD", rate: 1.1061 },
      { date: "2023-12-27", base_currency: "EUR", converted_currency: "USD", rate: 1.1106 },
      { date: "2023-12-26", base_currency: "EUR", converted_currency: "USD", rate: 1.1044 },
      { date: "2023-12-25", base_currency: "EUR", converted_currency: "USD", rate: 1.1017 },
      { date: "2023-12-22", base_currency: "EUR", converted_currency: "USD", rate: 1.1014 },
      { date: "2023-12-21", base_currency: "EUR", converted_currency: "USD", rate: 1.1011 },
      { date: "2023-12-20", base_currency: "EUR", converted_currency: "USD", rate: 1.0942 },
      { date: "2023-12-19", base_currency: "EUR", converted_currency: "USD", rate: 1.0980 },
      { date: "2023-12-18", base_currency: "EUR", converted_currency: "USD", rate: 1.0924 }
    ]

    ExchangeRate.upsert_all(exchange_rates, unique_by: :index_exchange_rates_on_base_converted_date_unique)

    puts "Demo data reset complete"
  end
end
