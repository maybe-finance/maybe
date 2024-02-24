class AccountBalanceSyncJob < ApplicationJob
  queue_as :default

  # Naive implementation of the perform method (will be refactored to handle transactions later)
  def perform(account_id:, valuation_date:, sync_type:, sync_action:)
    account = Account.find(account_id)

    account.status = "SYNCING"
    account.save!

    case sync_type
    when "valuation"
      case sync_action
      when "update"
        handle_valuation_update(account: account, valuation_date: valuation_date)
      when "destroy"
        handle_valuation_destroy(account: account, valuation_date: valuation_date)
      else
        logger.error "Unsupported sync_action: #{sync_action} for sync_type: #{sync_type}"
      end
    else
      logger.error "Unsupported sync_type: #{sync_type}"
    end

    sync_current_account_balance(account)

    account.status = "OK"
    account.save!
  end

  private

    def sync_current_account_balance(account)
      today_balance = account.balances.find_or_initialize_by(date: Date.current)
      today_balance.update(balance: account.converted_balance)
    end

    def handle_valuation_update(account:, valuation_date:)
      updated_valuation = account.valuations.find_by(date: valuation_date)

      return unless updated_valuation

      update_period_start = valuation_date
      update_period_end = (account.valuations.where("date > ?", valuation_date).order(:date).first&.date || Date.current) - 1.day

      balances_to_upsert = (update_period_start..update_period_end).map do |date|
        { date: date, balance: updated_valuation.value, created_at: Time.current, updated_at: Time.current }
      end

      account.balances.upsert_all(balances_to_upsert, unique_by: :index_account_balances_on_account_id_and_date)

      logger.info "Upserted balances for account #{account.id} from #{update_period_start} to #{update_period_end}"
    end

    def handle_valuation_destroy(account:, valuation_date:)
      prior_valuation = account.valuations.where("date < ?", valuation_date).order(:date).last
      period_start = prior_valuation&.date
      period_end = (account.valuations.where("date > ?", valuation_date).order(:date).first&.date || Date.current) - 1.day

      if prior_valuation
        balances_to_upsert = (period_start..period_end).map do |date|
          { date: date, balance: prior_valuation.value, created_at: Time.current, updated_at: Time.current }
        end

        account.balances.upsert_all(balances_to_upsert, unique_by: :index_account_balances_on_account_id_and_date)
        logger.info "Upserted balances for account #{account.id} from #{period_start} to #{period_end}"
      else
        delete_count = account.balances.where(date: period_start..period_end).delete_all
        logger.info "Deleted #{delete_count} balances for account #{account.id} from #{period_start} to #{period_end}"
      end
    rescue => e
      logger.error "Sync failed after valuation destroy operation on account #{account.id} with message: #{e.message}"
    end
end
