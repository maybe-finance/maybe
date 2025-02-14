class AccountStats
  attr_reader :family
  def initialize(family)
    @family = family
  end

  def totals_by_type
    totals = family.accounts
          .active
          .joins(ActiveRecord::Base.sanitize_sql_array([
            "LEFT JOIN exchange_rates ON exchange_rates.date = :current_date AND accounts.currency = exchange_rates.from_currency AND exchange_rates.to_currency = :family_currency",
            { current_date: Date.current.to_s, family_currency: family.currency }
          ]))
          .group(:accountable_type)
          .sum("accounts.balance * COALESCE(exchange_rates.rate, 1)")
          .transform_keys { |key| Accountable.from_type(key) }

    classification_totals = totals.group_by { |accountable, _| accountable.classification }

    asset_total = totals.select { |accountable, _| accountable.classification == "asset" }.sum { |_, total| total }
    liability_total = totals.select { |accountable, _| accountable.classification == "liability" }.sum { |_, total| total }

    totals.map do |accountable, total|
      group_total = accountable.classification == "asset" ? asset_total : liability_total

      weight = group_total.zero? ? 0 : total / group_total.to_f * 100

      TypeTotal.new(accountable: accountable, total_money: Money.new(total, family.currency), weight: weight, color: accountable.color, classification: accountable.classification)
    end
  end

  private
    TypeTotal = Struct.new(:accountable, :total_money, :weight, :color, :classification, keyword_init: true)
end
