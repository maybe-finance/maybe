class Account < ApplicationRecord
  include Syncable

  broadcasts_refreshes
  belongs_to :family
  has_many :balances, class_name: "AccountBalance"
  has_many :valuations
  has_many :transactions

  enum :status, { ok: "ok", syncing: "syncing", error: "error" }, validate: true

  scope :active, -> { where(is_active: true) }

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  before_create :check_currency

  def trend(period = Period.all)
    first = balances.in_period(period).order(:date).first
    last = balances.in_period(period).order(date: :desc).first
    Trend.new(current: last.balance, previous: first.balance, type: classification)
  end

  def self.by_provider
    # TODO: When 3rd party providers are supported, dynamically load all providers and their accounts
    [ { name: "Manual accounts", accounts: all.order(balance: :desc).group_by(&:accountable_type) } ]
  end

  def self.some_syncing?
    exists?(status: "syncing")
  end

  # TODO: We will need a better way to encapsulate large queries & transformation logic, but leaving all in one spot until
  # we have a better understanding of the requirements
  def self.by_group(period = Period.all)
    ranked_balances_cte = active.joins(:balances)
        .select("
          account_balances.account_id,
          account_balances.balance,
          account_balances.date,
          ROW_NUMBER() OVER (PARTITION BY account_balances.account_id ORDER BY date ASC) AS rn_asc,
          ROW_NUMBER() OVER (PARTITION BY account_balances.account_id ORDER BY date DESC) AS rn_desc
        ")

    if period.date_range
      ranked_balances_cte = ranked_balances_cte.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end)
    end

    accounts_with_period_balances = AccountBalance.with(
      ranked_balances: ranked_balances_cte
    )
      .from("ranked_balances AS rb")
      .joins("JOIN accounts a ON a.id = rb.account_id")
      .select("
        a.name,
        a.accountable_type,
        a.classification,
        SUM(CASE WHEN rb.rn_asc = 1 THEN rb.balance ELSE 0 END) AS start_balance,
        MAX(CASE WHEN rb.rn_asc = 1 THEN rb.date ELSE NULL END) as start_date,
        SUM(CASE WHEN rb.rn_desc = 1 THEN rb.balance ELSE 0 END) AS end_balance,
        MAX(CASE WHEN rb.rn_desc = 1 THEN rb.date ELSE NULL END) as end_date
      ")
      .where("rb.rn_asc = 1 OR rb.rn_desc = 1")
      .group("a.id")
      .order("end_balance")
      .to_a

    assets = accounts_with_period_balances.select { |row| row.classification == "asset" }
    liabilities = accounts_with_period_balances.select { |row| row.classification == "liability" }

    total_assets = assets.sum(&:end_balance)
    total_liabilities = liabilities.sum(&:end_balance)

    {
      asset: {
        total: total_assets,
        groups: assets.group_by(&:accountable_type).transform_values do |rows|
          end_balance = rows.sum(&:end_balance)
          start_balance = rows.sum(&:start_balance)
          {
            start_balance: start_balance,
            end_balance: end_balance,
            allocation: (end_balance / total_assets * 100).round(2),
            trend: Trend.new(current: end_balance, previous: start_balance, type: "asset"),
            accounts: rows.map do |account|
              {
                name: account.name,
                start_balance: account.start_balance,
                end_balance: account.end_balance,
                allocation: (account.end_balance / total_assets * 100).round(2),
                trend: Trend.new(current: account.end_balance, previous: account.start_balance, type: "asset")
              }
            end
          }
        end
      },
      liability: {
        total: total_liabilities,
        groups: liabilities.group_by(&:accountable_type).transform_values do |rows|
          end_balance = rows.sum(&:end_balance)
          start_balance = rows.sum(&:start_balance)
          {
            start_balance: start_balance,
            end_balance: end_balance,
            allocation: (end_balance / total_liabilities * 100).round(2),
            trend: Trend.new(current: end_balance, previous: start_balance, type: "liability"),
            accounts: rows.map do |account|
              {
                name: account.name,
                start_balance: account.start_balance,
                end_balance: account.end_balance,
                allocation: (account.end_balance / total_liabilities * 100).round(2),
                trend: Trend.new(current: account.end_balance, previous: account.start_balance, type: "liability")
              }
            end
          }
        end
      }
    }
  end

  private

    def check_currency
      if self.currency == self.family.currency
        self.converted_balance = self.balance
        self.converted_currency = self.currency
      else
        self.converted_balance = ExchangeRate.convert(self.currency, self.family.currency, self.balance)
        self.converted_currency = self.family.currency
      end
    end
end
