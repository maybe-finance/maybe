class Demo::AccountGenerator
  include Demo::DataHelper

  def create_credit_card_accounts!(family, count: 1)
    accounts = []
    count.times do |i|
      account = family.accounts.create!(
        accountable: CreditCard.new,
        name: account_name("Chase Credit Card", i, count),
        balance: realistic_balance(:credit_card, count),
        currency: "USD"
      )
      accounts << account
    end
    accounts
  end

  def create_checking_accounts!(family, count: 1)
    accounts = []
    count.times do |i|
      account = family.accounts.create!(
        accountable: Depository.new,
        name: account_name("Chase Checking", i, count),
        balance: realistic_balance(:checking, count),
        currency: "USD"
      )
      accounts << account
    end
    accounts
  end

  def create_savings_accounts!(family, count: 1)
    accounts = []
    count.times do |i|
      account = family.accounts.create!(
        accountable: Depository.new,
        name: account_name("Demo Savings", i, count),
        balance: realistic_balance(:savings, count),
        currency: "USD",
        subtype: "savings"
      )
      accounts << account
    end
    accounts
  end

  def create_properties_and_mortgages!(family, count: 1)
    accounts = []
    count.times do |i|
      property = family.accounts.create!(
        accountable: Property.new,
        name: account_name("123 Maybe Way", i, count),
        balance: realistic_balance(:property, count),
        currency: "USD"
      )
      accounts << property

      mortgage = family.accounts.create!(
        accountable: Loan.new,
        name: account_name("Mortgage", i, count),
        balance: realistic_balance(:mortgage, count),
        currency: "USD"
      )
      accounts << mortgage
    end
    accounts
  end

  def create_vehicles_and_loans!(family, vehicle_count: 1, loan_count: 1)
    accounts = []

    vehicle_count.times do |i|
      vehicle = family.accounts.create!(
        accountable: Vehicle.new,
        name: account_name("Honda Accord", i, vehicle_count),
        balance: realistic_balance(:vehicle, vehicle_count),
        currency: "USD"
      )
      accounts << vehicle
    end

    loan_count.times do |i|
      loan = family.accounts.create!(
        accountable: Loan.new,
        name: account_name("Car Loan", i, loan_count),
        balance: realistic_balance(:car_loan, loan_count),
        currency: "USD"
      )
      accounts << loan
    end

    accounts
  end

  def create_other_accounts!(family, asset_count: 1, liability_count: 1)
    accounts = []

    asset_count.times do |i|
      asset = family.accounts.create!(
        accountable: OtherAsset.new,
        name: account_name("Other Asset", i, asset_count),
        balance: realistic_balance(:other_asset, asset_count),
        currency: "USD"
      )
      accounts << asset
    end

    liability_count.times do |i|
      liability = family.accounts.create!(
        accountable: OtherLiability.new,
        name: account_name("Other Liability", i, liability_count),
        balance: realistic_balance(:other_liability, liability_count),
        currency: "USD"
      )
      accounts << liability
    end

    accounts
  end

  def create_investment_accounts!(family, count: 3)
    accounts = []

    if count <= 3
      account_configs = [
        { name: "401(k)", balance: 125000 },
        { name: "Roth IRA", balance: 45000 },
        { name: "Taxable Brokerage", balance: 75000 }
      ]

      count.times do |i|
        config = account_configs[i] || {
          name: "Investment Account #{i + 1}",
          balance: random_positive_amount(50000, 500000)
        }

        account = family.accounts.create!(
          accountable: Investment.new,
          name: config[:name],
          balance: config[:balance],
          currency: "USD"
        )
        accounts << account
      end
    else
      count.times do |i|
        account = family.accounts.create!(
          accountable: Investment.new,
          name: "Investment Account #{i + 1}",
          balance: random_positive_amount(50000, 500000),
          currency: "USD"
        )
        accounts << account
      end
    end

    accounts
  end

  private

    def realistic_balance(type, count = 1)
      return send("realistic_#{type}_balance") if count == 1
      send("random_#{type}_balance")
    end
    def realistic_credit_card_balance
      2300
    end

    def realistic_checking_balance
      15000
    end

    def realistic_savings_balance
      40000
    end

    def realistic_property_balance
      560000
    end

    def realistic_mortgage_balance
      495000
    end

    def realistic_vehicle_balance
      18000
    end

    def realistic_car_loan_balance
      8000
    end

    def realistic_other_asset_balance
      10000
    end

    def realistic_other_liability_balance
      5000
    end


    def random_credit_card_balance
      random_positive_amount(1000, 5000)
    end

    def random_checking_balance
      random_positive_amount(10000, 50000)
    end

    def random_savings_balance
      random_positive_amount(50000, 200000)
    end

    def random_property_balance
      random_positive_amount(400000, 800000)
    end

    def random_mortgage_balance
      random_positive_amount(200000, 600000)
    end

    def random_vehicle_balance
      random_positive_amount(15000, 50000)
    end

    def random_car_loan_balance
      random_positive_amount(5000, 25000)
    end

    def random_other_asset_balance
      random_positive_amount(5000, 50000)
    end

    def random_other_liability_balance
      random_positive_amount(2000, 20000)
    end
end
