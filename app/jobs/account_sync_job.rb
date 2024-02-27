class AccountSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id:, start_date: nil)
    account = Account.find(account_id)
    Account::Syncer.new(account).sync(start_date: start_date)
  end

  # def perform(sync_type:, sync_action:, account_id:, record_id:, date:)
  #   account = Account.find(account_id)

  #   account.status = "SYNCING"
  #   account.save!

  #   case sync_action
  #   when "update"
  #     handle_update(account: account, sync_type: sync_type, record_id: record_id)
  #   when "destroy"
  #     handle_destroy(account: account, sync_type: sync_type, date: date)
  #   else
  #     logger.error "Unsupported sync_type: #{sync_type}"
  #   end

  #   sync_current_account_balance(account)

  #   account.status = "OK"
  #   account.save!
  # end

  # private

  #   def sync_current_account_balance(account)
  #     today_balance = account.balances.find_or_initialize_by(date: Date.current)
  #     today_balance.update(balance: account.converted_balance)
  #   end

  #   def handle_update(account:, sync_type:, record_id:)
  #     case sync_type
  #     when "valuation"
  #       valuation = Valuation.find(record_id)
  #       handle_valuation_update(account: account, valuation: valuation)
  #     when "transaction"
  #       transaction = Transaction.find(record_id)
  #       handle_transaction_update(account: account, transaction: transaction)
  #     else
  #       logger.error "Unsupported sync_type: #{sync_type}"
  #     end
  #   end

  #   def handle_destroy(account:, sync_type:, date:)
  #     case sync_type
  #     when "valuation"
  #       handle_valuation_destroy(account: account, date: date)
  #     when "transaction"
  #       handle_transaction_destroy(account: account, date: date)
  #     else
  #       logger.error "Unsupported sync_type: #{sync_type}"
  #     end
  #   end

  #   def handle_valuation_update(account:, valuation:)
  #     return unless valuation

  #     update_period_start = valuation.date
  #     update_period_end = (account.valuations.where("date > ?", valuation.date).order(:date).first&.date || Date.current) - 1.day

  #     balances_to_upsert = (update_period_start..update_period_end).map do |date|
  #       { date: date, balance: valuation.value, created_at: Time.current, updated_at: Time.current }
  #     end

  #     account.balances.upsert_all(balances_to_upsert, unique_by: :index_account_balances_on_account_id_and_date)

  #     logger.info "Upserted balances for account #{account.id} from #{update_period_start} to #{update_period_end}"
  #   end

  #   def handle_valuation_destroy(account:, date:)
  #     prior_valuation = account.valuations.where("date < ?", date).order(:date).last
  #     period_start = prior_valuation&.date
  #     period_end = (account.valuations.where("date > ?", date).order(:date).first&.date || Date.current) - 1.day

  #     if prior_valuation
  #       balances_to_upsert = (period_start..period_end).map do |date|
  #         { date: date, balance: prior_valuation.value, created_at: Time.current, updated_at: Time.current }
  #       end

  #       account.balances.upsert_all(balances_to_upsert, unique_by: :index_account_balances_on_account_id_and_date)
  #       logger.info "Upserted balances for account #{account.id} from #{period_start} to #{period_end}"
  #     else
  #       delete_count = account.balances.where(date: period_start..period_end).delete_all
  #       logger.info "Deleted #{delete_count} balances for account #{account.id} from #{period_start} to #{period_end}"
  #     end
  #   rescue => e
  #     logger.error "Sync failed after valuation destroy operation on account #{account.id} with message: #{e.message}"
  #   end

  #   def handle_transaction_update(account:, transaction:)
  #     # Get or create account balance for the transaction date
  #     #
  #   end

  #   def handle_transaction_destroy(account:, date:)
  #     puts "Transaction destroy"
  #   end
end
