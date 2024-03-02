class Family < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts
  has_many :categories, dependent: :destroy

  after_create :create_default_categories

  def net_worth
    accounts.active.sum("CASE WHEN classification = 'asset' THEN balance ELSE -balance END")
  end

  def assets
    accounts.active.where(classification: "asset").sum(:balance)
  end

  def liabilities
    accounts.active.where(classification: "liability").sum(:balance)
  end

  def net_worth_series(period = nil)
    query = accounts.joins(:balances)
      .select("account_balances.date, SUM(CASE WHEN accounts.classification = 'asset' THEN account_balances.balance ELSE -account_balances.balance END) AS balance, 'USD' as currency")
      .group("account_balances.date")
      .order("account_balances.date ASC")

    if period && period.date_range
      query = query.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
    end

    MoneySeries.new(
      query,
      { trend_type: "asset" }
    )
  end

  def asset_series(period = nil)
    query = accounts.joins(:balances)
      .select("account_balances.date, SUM(account_balances.balance) AS balance, 'asset' AS classification, 'USD' AS currency")
      .group("account_balances.date")
      .order("account_balances.date ASC")
      .where(classification: "asset")

    if period && period.date_range
      query = query.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
    end

    MoneySeries.new(
      query,
      { trend_type: "asset" }
    )
  end

  def liability_series(period = nil)
    query = accounts.joins(:balances)
      .select("account_balances.date, SUM(account_balances.balance) AS balance, 'liability' AS classification, 'USD' AS currency")
      .group("account_balances.date")
      .order("account_balances.date ASC")
      .where(classification: "liability")

    if period && period.date_range
      query = query.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
    end

    MoneySeries.new(
      query,
      { trend_type: "liability" }
    )
  end

  private

    def create_default_categories
      Category.create(name: I18n.t("category.default_income_category"), color: "#abbd9a", category_type: :income, is_default: true, family: self)
      Category.create(name: I18n.t("category.default_expense_category"), color: "#942c3c", category_type: :expense, is_default: true, family: self)
    end
end
