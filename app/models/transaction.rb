class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :category, optional: true

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
