class Account::Transaction < ApplicationRecord
  include Account::Entryable

  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  has_one :transfer_as_inflow, class_name: "Transfer", foreign_key: "inflow_transaction_id", dependent: :destroy
  has_one :transfer_as_outflow, class_name: "Transfer", foreign_key: "outflow_transaction_id", dependent: :destroy

  # We keep track of rejected transfers to avoid auto-matching them again
  has_one :rejected_transfer_as_inflow, class_name: "RejectedTransfer", foreign_key: "inflow_transaction_id", dependent: :destroy
  has_one :rejected_transfer_as_outflow, class_name: "RejectedTransfer", foreign_key: "outflow_transaction_id", dependent: :destroy

  accepts_nested_attributes_for :taggings, allow_destroy: true

  scope :active, -> { where(excluded: false) }
  # Transactions are associated with accounts through entries
  scope :from_active_accounts, -> {
    joins("INNER JOIN account_entries active_entries ON active_entries.entryable_id = account_transactions.id AND active_entries.entryable_type = 'Account::Transaction'")
    .joins("INNER JOIN accounts active_accounts ON active_accounts.id = active_entries.account_id")
    .where(active_accounts: { is_active: true, scheduled_for_deletion: false })
  }

  class << self
    def search(params)
      Account::TransactionSearch.new(params).build_query(all)
    end
  end

  def transfer
    transfer_as_inflow || transfer_as_outflow
  end

  def transfer?
    transfer.present?
  end
end
