class Account < ApplicationRecord
  include Syncable, Monetizable, Issuable

  validates :name, :balance, :currency, presence: true

  belongs_to :family
  belongs_to :import, optional: true
  belongs_to :plaid_account, optional: true

  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"
  has_many :entries, dependent: :destroy, class_name: "Account::Entry"
  has_many :transactions, through: :entries, source: :entryable, source_type: "Account::Transaction"
  has_many :valuations, through: :entries, source: :entryable, source_type: "Account::Valuation"
  has_many :trades, through: :entries, source: :entryable, source_type: "Account::Trade"
  has_many :holdings, dependent: :destroy, class_name: "Account::Holding"
  has_many :balances, dependent: :destroy
  has_many :issues, as: :issuable, dependent: :destroy

  monetize :balance, :cash_balance

  enum :classification, { asset: "asset", liability: "liability" }, validate: { allow_nil: true }

  scope :active, -> { where(is_active: true, scheduled_for_deletion: false) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }
  scope :alphabetically, -> { order(:name) }
  scope :manual, -> { where(plaid_account_id: nil) }

  has_one_attached :logo

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  accepts_nested_attributes_for :accountable, update_only: true

  def transfer_match_candidates
    Account::Entry.select([
      "inflow_candidates.entryable_id as inflow_transaction_id",
      "outflow_candidates.entryable_id as outflow_transaction_id",
      "ABS(inflow_candidates.date - outflow_candidates.date) as date_diff"
    ]).from("account_entries inflow_candidates")
      .joins("
        JOIN account_entries outflow_candidates ON (
          inflow_candidates.amount < 0 AND
          outflow_candidates.amount > 0 AND
          inflow_candidates.amount = -outflow_candidates.amount AND
          inflow_candidates.currency = outflow_candidates.currency AND
          inflow_candidates.account_id <> outflow_candidates.account_id AND
          inflow_candidates.date BETWEEN outflow_candidates.date - 4 AND outflow_candidates.date + 4
        )
      ")
      .joins("
        LEFT JOIN transfers existing_transfers ON (
          existing_transfers.inflow_transaction_id IN (inflow_candidates.entryable_id, outflow_candidates.entryable_id) OR
          existing_transfers.outflow_transaction_id IN (inflow_candidates.entryable_id, outflow_candidates.entryable_id)
        )
      ")
      .joins("LEFT JOIN rejected_transfers ON (
        rejected_transfers.inflow_transaction_id = inflow_candidates.entryable_id AND
        rejected_transfers.outflow_transaction_id = outflow_candidates.entryable_id
      )")
      .joins("JOIN accounts inflow_accounts ON inflow_accounts.id = inflow_candidates.account_id")
      .joins("JOIN accounts outflow_accounts ON outflow_accounts.id = outflow_candidates.account_id")
      .where("inflow_accounts.family_id = ? AND outflow_accounts.family_id = ?", self.family_id, self.family_id)
      .where("inflow_candidates.entryable_type = 'Account::Transaction' AND outflow_candidates.entryable_type = 'Account::Transaction'")
      .where(existing_transfers: { id: nil })
      .order("date_diff ASC")
  end

  # Rest of the Account class implementation remains unchanged
end
