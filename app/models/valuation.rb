class Valuation < ApplicationRecord
  belongs_to :account

  after_commit :sync_account_balances, on: [ :create, :update ]
  after_destroy :sync_account_balances_after_destroy

  def trend(previous)
    Trend.new(value, previous&.value)
  end

  private

    def sync_account_balances_after_destroy
      AccountBalanceSyncJob.perform_later(account_id: account_id, valuation_date: date, sync_type: "valuation", sync_action: "destroy")
    end

    def sync_account_balances
      AccountBalanceSyncJob.perform_later(account_id: account_id, valuation_date: date, sync_type: "valuation", sync_action: "update")
    end
end
