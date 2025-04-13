module Accountable
  extend ActiveSupport::Concern

  TYPES = %w[Depository Investment Crypto Property Vehicle OtherAsset CreditCard Loan OtherLiability]

  def self.from_type(type)
    return nil unless TYPES.include?(type)
    type.constantize
  end

  included do
    include Enrichable

    has_one :account, as: :accountable, touch: true
  end

  class_methods do
    def classification
      raise NotImplementedError, "Accountable must implement #classification"
    end

    def icon
      raise NotImplementedError, "Accountable must implement #icon"
    end

    def color
      raise NotImplementedError, "Accountable must implement #color"
    end

    def favorable_direction
      classification == "asset" ? "up" : "down"
    end

    def display_name
      self.name.pluralize.titleize
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
  end

  def post_sync(sync)
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

  def icon
    self.class.icon
  end

  def color
    self.class.color
  end

  def classification
    self.class.classification
  end
end
