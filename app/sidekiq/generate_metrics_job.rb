class GenerateMetricsJob
  include Sidekiq::Job

  def perform(family_id)
    family = Family.find(family_id)

    accounts = family.accounts

    depository_accounts_balance = accounts.depository.sum { |account| account.current_balance }

    investment_accounts_balance = accounts.investment.sum { |account| account.current_balance }

    credit_accounts_balance = accounts.credit.sum { |account| account.current_balance }

    property_accounts_balance = accounts.property.sum { |account| account.current_balance }

    total_assets = depository_accounts_balance + investment_accounts_balance + property_accounts_balance
    
    total_debts = credit_accounts_balance

    net_worth = total_assets - total_debts

    Metric.find_or_create_by(kind: 'depository_balance', family: family, date: Date.today).update(amount: depository_accounts_balance)
    Metric.find_or_create_by(kind: 'investment_balance', family: family, date: Date.today).update(amount: investment_accounts_balance)
    Metric.find_or_create_by(kind: 'total_assets', family: family, date: Date.today).update(amount: total_assets)
    Metric.find_or_create_by(kind: 'total_debts', family: family, date: Date.today).update(amount: total_debts)
    Metric.find_or_create_by(kind: 'net_worth', family: family, date: Date.today).update(amount: net_worth)
    Metric.find_or_create_by(kind: 'credit_balance', family: family, date: Date.today).update(amount: credit_accounts_balance)
    Metric.find_or_create_by(kind: 'property_balance', family: family, date: Date.today).update(amount: property_accounts_balance)
  end
end
