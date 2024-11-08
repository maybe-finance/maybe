class PlaidItemSync < ApplicationRecord
  belongs_to :plaid_item

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  def run
    start!

    initialize_item unless plaid_item.plaid_accounts.any?

    sync_accounts

    complete!
  rescue StandardError => error
    fail! error

    raise error if Rails.env.development?
  end

  private
    def family
      plaid_item.family
    end

    def initialize_item
      accounts_data = plaid_item.fetch_accounts.accounts

      transaction do
        accounts_data.each do |account_data|
          plaid_item.plaid_accounts
                    .create_from_plaid_data!(account_data, family)
        end
      end
    end

    def sync_accounts
      plaid_item.accounts.each do |account|
        account.sync
      end
    end

    def start!
      update! status: "syncing", last_ran_at: Time.now
    end

    def complete!
      update! status: "completed"
    end

    def fail!(error)
      update! status: "failed", error: error.message
    end
end
