class Security < ApplicationRecord
  has_many :security_prices
  has_many :holdings
  has_many :balances

  # After creating a security, sync the price history
  after_create :sync_price_history

  def sync_price_history
    SyncSecurityHistoryJob.perform_async(self.id)
  end
end
