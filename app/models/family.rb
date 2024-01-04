class Family < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts
  has_many :connections, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :holdings, dependent: :destroy
  has_many :metrics, dependent: :destroy
  has_many :balances, dependent: :destroy

  def metrics
    Metric.where(family_id: self.id)
  end

  def net_worth
    metrics.where(kind: 'net_worth').order(date: :desc).first&.amount || 0
  end

  def total_assets
    metrics.where(kind: 'total_assets').order(date: :desc).first&.amount || 0
  end

  def total_debts
    metrics.where(kind: 'total_debts').order(date: :desc).first&.amount || 0
  end

  def cash_balance
    metrics.where(kind: 'depository_balance').order(date: :desc).first&.amount || 0
  end

  def credit_balance
    # If no metrics exist, return 0
    metrics.where(kind: 'credit_balance').order(date: :desc).first&.amount || 0
  end

  def investment_balance
    metrics.where(kind: 'investment_balance').order(date: :desc).first&.amount || 0
  end

  def property_balance
    metrics.where(kind: 'property_balance').order(date: :desc).first&.amount || 0
  end

  # Demographics JSONB sample
  # {
  #   "spouse_1_age": 35,
  #   "spouse_2_age": 30,
  #   "dependents": 2,
  #   "dependents_ages": [5, 10],
  #   "gross_income": 100000,
  #   "income_types": ["salary"], // or "self-employed", "retired", "other"
  #   "tax_status": "married filing jointly", // or "single", "married filing separately", "head of household"
  #   "risk_tolerance": "conservative", // or "moderate", "aggressive"
  #   "investment_horizon": "short", // or "medium", "long"
  #   "investment_objective": "retirement", // or "college", "emergency", "other"
  #   "investment_experience": "beginner", // or "intermediate", "advanced"
  #   "investment_knowledge": "beginner", // or "intermediate", "advanced"
  #   "investment_style": "passive", // or "active"
  #   "investment_strategy": "index", // or "active"
  #   "investment_frequency": "monthly", // or "quarterly", "semi-annually", "annually"
  #   "goals": ['retire by 65', 'buy a house by 30', 'save for college', 'learn to invest']
  # }
end
