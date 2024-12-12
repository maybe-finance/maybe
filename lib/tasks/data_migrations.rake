# Used to run non-schema-related data migrations (e.g. cleaning up data according to new requirements)
namespace :data_migrations do
  desc "Update Plaid cash balance handling"
  task plaid_cash_handling: :environment do
    cash_security = Security.find_by(ticker: "CUR:USD")

    cash_trade_entries = Account::Trade.where(security: cash_security)
      .includes(:entry)
      .map(&:entry)

    Account.transaction do
      cash_trade_entries.each do |trade_entry|
        old_entryable = trade_entry.entryable
        trade_entry.update!(entryable: Account::Transaction.new)
        old_entryable.destroy!
      end

      Account::Holding.where(security: cash_security).destroy_all

      cash_security.destroy!
    end
  end
end
