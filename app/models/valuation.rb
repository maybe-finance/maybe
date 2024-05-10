class Valuation < ApplicationRecord
  include Monetizable

  belongs_to :account
  validates :account, :date, :value, presence: true
  monetize :value

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  # after_create :update_account_balance_after_create
  # after_update :update_account_balance_after_update
  # after_destroy :update_account_balance_after_destroy
  #
  # def update_account_balance_after_create
  #   newer_valuation_exists = self.account.valuations.where("date > ?", self.date).exists?
  #   if self.account.manual?
  #
  #     self.account.balance -= self.amount
  #     self.account.save!
  #   end
  # end
  #
  # def update_account_balance_after_update
  #   # newer_valuation_exists = self.account.valuations.where("date >= ?", self.date).exists?
  #   # if self.account.manual? && self.amount_changed? && !newer_valuation_exists
  #   #   self.account.balance += (self.amount - self.amount_was)
  #   #   self.account.save!
  #   # end
  # end
  #
  # def update_account_balance_after_destroy
  #   # newer_valuation_exists = self.account.valuations.where("date >= ?", self.date).exists?
  #   # if self.account.manual? && !newer_valuation_exists
  #   #   self.account.balance += self.amount
  #   #   self.account.save!
  #   # end
  # end

  def self.to_series
    TimeSeries.from_collection all, :value_money
  end
end
