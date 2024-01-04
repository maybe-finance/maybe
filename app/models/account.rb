class Account < ApplicationRecord
  belongs_to :connection
  belongs_to :family
  has_many :transactions, dependent: :destroy
  has_many :balances, dependent: :destroy
  has_many :holdings, dependent: :destroy
  has_many :investment_transactions, dependent: :destroy

  enum sync_status: { idle: 0, pending: 1, syncing: 2 }
  enum source: { plaid: 0, manual: 1 }

  after_update :log_changes

  scope :depository, -> { where(kind: 'depository') }
  scope :investment, -> { where(kind: 'investment') }
  scope :credit, -> { where(kind: 'credit') }
  scope :property, -> { where(kind: 'property') }


  private

  def log_changes
    ignored_attributes = ['updated_at', 'subkind', 'current_balance_date']

    saved_changes.except(*ignored_attributes).each do |attr, (old_val, new_val)|
      ChangeLog.create(
        record_type: self.class.name,
        record_id: id,
        attribute_name: attr,
        old_value: old_val,
        new_value: new_val
      )
    end
  end
end
