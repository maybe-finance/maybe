class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :category, optional: true

  validates :name, :date, :amount, :account_id, presence: true

  after_commit :sync_account

  def self.ransackable_attributes(auth_object = nil)
    %w[name amount date]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[category account]
  end

  private

    def sync_account
      self.account.sync_later
    end
end
