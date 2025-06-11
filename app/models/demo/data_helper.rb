module Demo::DataHelper
  COLORS = %w[#e99537 #4da568 #6471eb #db5a54 #df4e92 #c44fe9 #eb5429 #61c9ea #805dee #6ad28a].freeze

  PERFORMANCE_TRANSACTION_COUNTS = {
    depository_sample: 75,
    credit_card_sample: 75,
    investment_trades: 35,
    investment_transactions: 35,
    other_account_sample: 20
  }.freeze

  module_function

  def random_date_within_days(max_days_ago)
    Faker::Number.between(from: 0, to: max_days_ago).days.ago.to_date
  end

  def random_amount(min, max)
    Faker::Number.between(from: min, to: max)
  end

  def random_positive_amount(min, max)
    Faker::Number.positive(from: min, to: max)
  end

  def group_accounts_by_type(family)
    accounts = family.accounts.includes(:accountable)

    {
      checking: filter_checking_accounts(accounts),
      savings: filter_savings_accounts(accounts),
      credit_cards: filter_credit_card_accounts(accounts),
      investments: filter_investment_accounts(accounts),
      loans: filter_loan_accounts(accounts),
      properties: filter_property_accounts(accounts),
      vehicles: filter_vehicle_accounts(accounts),
      other_assets: filter_other_asset_accounts(accounts),
      other_liabilities: filter_other_liability_accounts(accounts)
    }
  end

  def filter_checking_accounts(accounts)
    accounts.select { |a| a.accountable_type == "Depository" && (a.subtype != "savings" || a.name.include?("Checking")) }
  end

  def filter_savings_accounts(accounts)
    accounts.select { |a| a.accountable_type == "Depository" && (a.subtype == "savings" || a.name.include?("Savings")) }
  end

  def filter_credit_card_accounts(accounts)
    accounts.select { |a| a.accountable_type == "CreditCard" }
  end

  def filter_investment_accounts(accounts)
    accounts.select { |a| a.accountable_type == "Investment" }
  end

  def filter_loan_accounts(accounts)
    accounts.select { |a| a.accountable_type == "Loan" }
  end

  def filter_property_accounts(accounts)
    accounts.select { |a| a.accountable_type == "Property" }
  end

  def filter_vehicle_accounts(accounts)
    accounts.select { |a| a.accountable_type == "Vehicle" }
  end

  def filter_other_asset_accounts(accounts)
    accounts.select { |a| a.accountable_type == "OtherAsset" }
  end

  def filter_other_liability_accounts(accounts)
    accounts.select { |a| a.accountable_type == "OtherLiability" }
  end

  def random_color
    COLORS.sample
  end

  def account_name(base_name, index, count = 1)
    count == 1 ? base_name : "#{base_name} #{index + 1}"
  end
end
