class BalanceSheet
  include Monetizable

  monetize :total_assets, :total_liabilities, :net_worth

  attr_reader :family

  def initialize(family)
    @family = family
  end

  def total_assets
    totals_query.filter { |t| t.classification == "asset" }.sum(&:converted_balance)
  end

  def total_liabilities
    totals_query.filter { |t| t.classification == "liability" }.sum(&:converted_balance)
  end

  def net_worth
    total_assets - total_liabilities
  end

  def classification_groups
    [
      ClassificationGroup.new(
        key: "asset",
        display_name: "Assets",
        icon: "plus",
        total_money: total_assets_money,
        account_groups: account_groups("asset")
      ),
      ClassificationGroup.new(
        key: "liability",
        display_name: "Debts",
        icon: "minus",
        total_money: total_liabilities_money,
        account_groups: account_groups("liability")
      )
    ]
  end

  def account_groups(classification = nil)
    classification_accounts = classification ? totals_query.filter { |t| t.classification == classification } : totals_query
    classification_total = classification_accounts.sum(&:converted_balance)
    account_groups = classification_accounts.group_by(&:accountable_type).transform_keys { |k| Accountable.from_type(k) }

    account_groups.map do |accountable, accounts|
      group_total = accounts.sum(&:converted_balance)

      AccountGroup.new(
        key: accountable.model_name.param_key,
        name: accountable.display_name,
        classification: accountable.classification,
        total: group_total,
        total_money: Money.new(group_total, currency),
        weight: classification_total.zero? ? 0 : group_total / classification_total.to_d * 100,
        missing_rates?: accounts.any? { |a| a.missing_rates? },
        color: accountable.color,
        accounts: accounts.map do |account|
          account.define_singleton_method(:weight) do
            classification_total.zero? ? 0 : account.converted_balance / classification_total.to_d * 100
          end

          account
        end.sort_by(&:weight).reverse
      )
    end.sort_by(&:weight).reverse
  end

  def net_worth_series(period: Period.last_30_days)
    active_accounts.balance_series(currency: currency, period: period, favorable_direction: "up")
  end

  def currency
    family.currency
  end

  private
    ClassificationGroup = Struct.new(:key, :display_name, :icon, :total_money, :account_groups, keyword_init: true)
    AccountGroup = Struct.new(:key, :name, :accountable_type, :classification, :total, :total_money, :weight, :accounts, :color, :missing_rates?, keyword_init: true)

    def active_accounts
      family.accounts.active.with_attached_logo
    end

    def totals_query
      @totals_query ||= active_accounts
            .joins(ActiveRecord::Base.sanitize_sql_array([ "LEFT JOIN exchange_rates ON exchange_rates.date = CURRENT_DATE AND accounts.currency = exchange_rates.from_currency AND exchange_rates.to_currency = ?", currency ]))
            .select(
              "accounts.*",
              "SUM(accounts.balance * COALESCE(exchange_rates.rate, 1)) as converted_balance",
              ActiveRecord::Base.sanitize_sql_array([ "COUNT(CASE WHEN accounts.currency <> ? AND exchange_rates.rate IS NULL THEN 1 END) as missing_rates", currency ])
            )
            .group(:classification, :accountable_type, :id)
            .to_a
    end
end
