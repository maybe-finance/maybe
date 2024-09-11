class Institution < ApplicationRecord
  belongs_to :family
  has_many :accounts, dependent: :nullify
  has_one_attached :logo

  scope :alphabetically, -> { order(name: :asc) }

  def sync
    accounts.active.each do |account|
      if account.needs_sync?
        account.sync
      end
    end

    update! last_synced_at: Time.now
  end

  def syncing?
    accounts.active.any? { |account| account.syncing? }
  end

  def has_issues?
    accounts.active.any? { |account| account.has_issues? }
  end
end
