class Transaction < ApplicationRecord
  include Monetizable
  include Provided

  belongs_to :account
  belongs_to :category, optional: true

  validates :name, :date, :amount, :account, presence: true

  after_commit :sync_account

  monetize :amount

  scope :inflows, -> { where("amount > 0") }
  scope :outflows, -> { where("amount < 0") }
  scope :active, -> { where(excluded: false) }

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
