module Accountable
  extend ActiveSupport::Concern

  ASSET_TYPES = %w[Depository Investment Crypto Property Vehicle OtherAsset]
  LIABILITY_TYPES = %w[CreditCard Loan OtherLiability]
  TYPES = ASSET_TYPES + LIABILITY_TYPES

  def self.from_type(type)
    return nil unless TYPES.include?(type)
    type.constantize
  end

  def self.by_classification
    { assets: ASSET_TYPES, liabilities: LIABILITY_TYPES }
  end

  included do
    has_one :account, as: :accountable, touch: true
  end

  class_methods do
    def classification
      self.name.in?(ASSET_TYPES) ? "asset" : "liability"
    end

    def display_name
      self.name.humanize
    end

    def balance_money(family)
      family.accounts
            .active
            .joins(sanitize_sql_array([
              "LEFT JOIN exchange_rates ON exchange_rates.date = :current_date AND accounts.currency = exchange_rates.from_currency AND exchange_rates.to_currency = :family_currency",
              { current_date: Date.current.to_s, family_currency: family.currency }
            ]))
            .where(accountable_type: self.name)
            .sum("accounts.balance * COALESCE(exchange_rates.rate, 1)")
    end

    def series(family)
      period = Period.last_30_days
      start_date = period.date_range.first
      end_date = period.date_range.last

      query = <<~SQL
        WITH dates as (
          SELECT generate_series(DATE :start_date, DATE :end_date, '1 day'::interval)::date as date
        )
        SELECT
          d.date,
          COALESCE(SUM(ab.balance * COALESCE(er.rate, 1)), 0) as balance,
          COUNT(CASE WHEN a.currency <> 'USD' AND er.rate IS NULL THEN 1 END) as missing_rates
        FROM dates d
        LEFT JOIN accounts a ON (
          a.accountable_type = :accountable_type AND
          a.family_id = :family_id
        )
        LEFT JOIN account_balances ab ON (
          ab.date = d.date AND
          ab.currency = a.currency AND
          ab.account_id = a.id
        )
        LEFT JOIN exchange_rates er ON (
          er.date = ab.date AND
          er.from_currency = a.currency AND
          er.to_currency = :family_currency
        )
        GROUP BY d.date
        ORDER BY d.date
      SQL

      balances = Account::Balance.find_by_sql([
        query,
        accountable_type: self.name,
        family_id: family.id,
        family_currency: family.currency,
        start_date: start_date,
        end_date: end_date
      ])

      TimeSeries.from_collection(balances, :balance, favorable_direction: self.name.in?(ASSET_TYPES) ? "up" : "down")
    end
  end

  def post_sync
    broadcast_replace_to(
      account,
      target: "chart_account_#{account.id}",
      partial: "accounts/show/chart",
      locals: { account: account }
    )
  end

  def display_name
    self.class.display_name
  end

  def classification
    self.class.classification
  end
end
