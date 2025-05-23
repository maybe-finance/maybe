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
    Rails.cache.fetch(family.build_cache_key("bs_classification_groups")) do
      asset_groups     = account_groups("asset")
      liability_groups = account_groups("liability")

      [
        ClassificationGroup.new(
          key: "asset",
          display_name: "Assets",
          icon: "plus",
          total_money: total_assets_money,
          account_groups: asset_groups,
          syncing?: asset_groups.any?(&:syncing?)
        ),
        ClassificationGroup.new(
          key: "liability",
          display_name: "Debts",
          icon: "minus",
          total_money: total_liabilities_money,
          account_groups: liability_groups,
          syncing?: liability_groups.any?(&:syncing?)
        )
      ]
    end
  end

  def account_groups(classification = nil)
    Rails.cache.fetch(family.build_cache_key("bs_account_groups_#{classification || 'all'}")) do
      classification_accounts = classification ? totals_query.filter { |t| t.classification == classification } : totals_query
      classification_total    = classification_accounts.sum(&:converted_balance)

      account_groups = classification_accounts.group_by(&:accountable_type)
                                              .transform_keys { |k| Accountable.from_type(k) }

      groups = account_groups.map do |accountable, accounts|
        group_total = accounts.sum(&:converted_balance)

        key = accountable.model_name.param_key

        AccountGroup.new(
          id: classification ? "#{classification}_#{key}_group" : "#{key}_group",
          key: key,
          name: accountable.display_name,
          classification: accountable.classification,
          total: group_total,
          total_money: Money.new(group_total, currency),
          weight: classification_total.zero? ? 0 : group_total / classification_total.to_d * 100,
          missing_rates?: accounts.any? { |a| a.missing_rates? },
          color: accountable.color,
          syncing?: accounts.any?(&:is_syncing),
          accounts: accounts.map do |account|
            account.define_singleton_method(:weight) do
              classification_total.zero? ? 0 : account.converted_balance / classification_total.to_d * 100
            end

            account
          end.sort_by(&:weight).reverse
        )
      end

      groups.sort_by do |group|
        manual_order = Accountable::TYPES
        type_name    = group.key.camelize
        manual_order.index(type_name) || Float::INFINITY
      end
    end
  end

  def net_worth_series(period: Period.last_30_days)
    active_accounts.balance_series(currency: currency, period: period, favorable_direction: "up")
  end

  def currency
    family.currency
  end

  def syncing?
    classification_groups.any? { |group| group.syncing? }
  end

  private
    ClassificationGroup = Struct.new(:key, :display_name, :icon, :total_money, :account_groups, :syncing?, keyword_init: true)
    AccountGroup = Struct.new(:id, :key, :name, :accountable_type, :classification, :total, :total_money, :weight, :accounts, :color, :missing_rates?, :syncing?, keyword_init: true)

    def active_accounts
      family.accounts.active.with_attached_logo
    end

    def totals_query
      @totals_query ||= active_accounts
            .joins(ActiveRecord::Base.sanitize_sql_array([ "LEFT JOIN exchange_rates ON exchange_rates.date = CURRENT_DATE AND accounts.currency = exchange_rates.from_currency AND exchange_rates.to_currency = ?", currency ]))
            .joins(ActiveRecord::Base.sanitize_sql_array([
              "LEFT JOIN syncs ON syncs.syncable_id = accounts.id AND syncs.syncable_type = 'Account' AND syncs.status IN (?) AND syncs.created_at > ?",
              %w[pending syncing],
              Sync::VISIBLE_FOR.ago
            ]))
            .select(
              "accounts.*",
              "SUM(accounts.balance * COALESCE(exchange_rates.rate, 1)) as converted_balance",
              "COUNT(syncs.id) > 0 as is_syncing",
              ActiveRecord::Base.sanitize_sql_array([ "COUNT(CASE WHEN accounts.currency <> ? AND exchange_rates.rate IS NULL THEN 1 END) as missing_rates", currency ])
            )
            .group(:classification, :accountable_type, :id)
            .to_a
    end
end
