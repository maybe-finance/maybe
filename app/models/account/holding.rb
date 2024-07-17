class Account::Holding < ApplicationRecord
  belongs_to :account
  belongs_to :security

  scope :chronological, -> { order(:date) }
  scope :current, -> { where(date: Date.current).order(amount: :desc) }
end
