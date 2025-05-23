class PlaidItem::Syncer
  attr_reader :plaid_item

  def initialize(plaid_item)
    @plaid_item = plaid_item
  end

  def perform_sync(sync)
    # Loads item metadata, accounts, transactions, and other data to our DB
    plaid_item.import_latest_plaid_data

    # Processes the raw Plaid data and updates internal domain objects
    plaid_item.process_accounts

    # All data is synced, so we can now run an account sync to calculate historical balances and more
    plaid_item.schedule_account_syncs(
      parent_sync: sync,
      window_start_date: sync.window_start_date,
      window_end_date: sync.window_end_date
    )
  end

  def perform_post_sync
    # no-op
  end

  private
    def safe_fetch_plaid_data(method)
      begin
        plaid.send(method, plaid_item)
      rescue Plaid::ApiError => e
        Rails.logger.warn("Error fetching #{method} for item #{plaid_item.id}: #{e.message}")
        nil
      end
    end

    def handle_plaid_error(error)
      error_body = JSON.parse(error.response_body)

      if error_body["error_code"] == "ITEM_LOGIN_REQUIRED"
        plaid_item.update!(status: :requires_update)
      end
    end

    def fetch_and_load_plaid_data
      # Investments
      fetched_investments = safe_fetch_plaid_data(:get_item_investments)
      data[:investments] = fetched_investments || []

      if fetched_investments
        Rails.logger.info "Processing Plaid investments (transactions: #{fetched_investments.transactions.size}, holdings: #{fetched_investments.holdings.size}, securities: #{fetched_investments.securities.size})"
        PlaidItem.transaction do
          internal_plaid_accounts.each do |internal_plaid_account|
            transactions = fetched_investments.transactions.select { |t| t.account_id == internal_plaid_account.plaid_id }
            holdings = fetched_investments.holdings.select { |h| h.account_id == internal_plaid_account.plaid_id }
            securities = fetched_investments.securities

            internal_plaid_account.sync_investments!(transactions:, holdings:, securities:)
          end
        end
      end

      # Liabilities
      fetched_liabilities = safe_fetch_plaid_data(:get_item_liabilities)
      data[:liabilities] = fetched_liabilities || []

      if fetched_liabilities
        Rails.logger.info "Processing Plaid liabilities (credit: #{fetched_liabilities.credit&.size || 0}, mortgage: #{fetched_liabilities.mortgage&.size || 0}, student: #{fetched_liabilities.student&.size || 0})"
        PlaidItem.transaction do
          internal_plaid_accounts.each do |internal_plaid_account|
            credit = fetched_liabilities.credit&.find { |l| l.account_id == internal_plaid_account.plaid_id }
            mortgage = fetched_liabilities.mortgage&.find { |l| l.account_id == internal_plaid_account.plaid_id }
            student = fetched_liabilities.student&.find { |l| l.account_id == internal_plaid_account.plaid_id }

            internal_plaid_account.sync_credit_data!(credit) if credit
            internal_plaid_account.sync_mortgage_data!(mortgage) if mortgage
            internal_plaid_account.sync_student_loan_data!(student) if student
          end
        end
      end
    end
end
