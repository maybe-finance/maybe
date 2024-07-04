class Account::Sync < ApplicationRecord
  include Syncable

  belongs_to :account

  enum status: { pending: "pending", running: "running", completed: "completed", failed: "failed" }

  def start(start_date = nil)
    start!(start_date)

    sync_exchange_rates
    sync_securities_prices
    sync_holdings
    sync_balances

    complete!
  rescue StandardError => error
    fail! error: error
  end

  class << self
    def for(account)
      create! account: account
    end
  end

  private

    def process_sync(sync_response)
      unless sync_response.success?
        raise sync_response.errors.join(", ")
      end

      append_warnings(sync_response.warnings)
    end

    def append_warnings(new_warnings)
      update! warnings: warnings + new_warnings.map(&:message)
    end

    def start!(start_date = nil)
      update! start_date: start_date, status: "running"
    end

    def complete!
      update! status: "completed"
    end

    def fail!(error)
      update! status: "failed", error: error.message
    end

    def sync_exchange_rates
      process_sync ExchangeRate.sync(account, start_date)
    end

    def sync_securities_prices
      process_sync Security.sync(account, start_date)
    end

    def sync_holdings
      process_sync Account::Holding.sync(account, start_date)
    end

    def sync_balances
      process_sync Account::Balance.sync(account, start_date)
    end
end
