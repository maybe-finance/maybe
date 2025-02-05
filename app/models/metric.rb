class Metric < ApplicationRecord
  belongs_to :family
  belongs_to :account, optional: true

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }
  scope :for, ->(metric_kind) { where(kind: metric_kind) }

  def family_level?
    account.nil?
  end

  def account_level?
    account.present?
  end
end
