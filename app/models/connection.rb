class Connection < ApplicationRecord
  belongs_to :user
  belongs_to :family
  has_many :accounts, dependent: :destroy
  belongs_to :institution, optional: true, foreign_key: :aggregator_id, primary_key: :provider_id

  enum source: { plaid: 0, manual: 1 }
  enum status: { ok: 0, error: 1, disconnected: 2 }
  enum sync_status: { idle: 0, pending: 1, syncing: 2 }

  scope :error, -> { where(status: :error) }
  
  def has_investments?
    plaid_products.include? 'investments'
  end

  def has_transactions?
    plaid_products.include? 'transactions'
  end
end
