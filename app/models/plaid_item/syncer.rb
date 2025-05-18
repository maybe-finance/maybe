class PlaidItem::Syncer
  attr_reader :plaid_item

  def initialize(plaid_item)
    @plaid_item = plaid_item
  end

  def perform_sync(sync)
    # Loads item metadata, accounts, transactions, and other data to our DB
    import_item_data

    # Processes the raw Plaid data and updates internal domain objects
    process_item_data

    # All data is synced, so we can now run an account sync to calculate historical balances and more
    plaid_item.reload.accounts.each do |account|
      account.sync_later(
        parent_sync: sync,
        window_start_date: sync.window_start_date,
        window_end_date: sync.window_end_date
      )
    end
  end

  def perform_post_sync
    plaid_item.auto_match_categories!
  end

  private
    def plaid
      plaid_item.plaid_provider
    end

    def import_item_data
      PlaidItem::Importer.new(plaid_item).import_data
    end

    def process_item_data
      PlaidItem::Processor.new(plaid_item).process_data
    end

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
      data = {}

      # Log what we're about to fetch
      Rails.logger.info "Starting Plaid data fetch (accounts, transactions, investments, liabilities)"

      item = plaid.get_item(plaid_item.access_token).item
      plaid_item.update!(available_products: item.available_products, billed_products: item.billed_products)

      # Institution details
      if item.institution_id.present?
        begin
          Rails.logger.info "Fetching Plaid institution details for #{item.institution_id}"
          institution = plaid.get_institution(item.institution_id)
          plaid_item.update!(
            institution_id: item.institution_id,
            institution_url: institution.institution.url,
            institution_color: institution.institution.primary_color
          )
        rescue Plaid::ApiError => e
          Rails.logger.warn "Failed to fetch Plaid institution details: #{e.message}"
        end
      end

      # Accounts
      fetched_accounts = plaid.get_item_accounts(plaid_item).accounts
      data[:accounts] = fetched_accounts || []
      Rails.logger.info "Processing Plaid accounts (count: #{fetched_accounts.size})"

      internal_plaid_accounts = fetched_accounts.map do |account|
        internal_plaid_account = plaid_item.plaid_accounts.find_or_create_from_plaid_data!(account, plaid_item.family)
        internal_plaid_account.sync_account_data!(account)
        internal_plaid_account
      end

      # Transactions
      fetched_transactions = safe_fetch_plaid_data(:get_item_transactions)
      data[:transactions] = fetched_transactions || []

      if fetched_transactions
        Rails.logger.info "Processing Plaid transactions (added: #{fetched_transactions.added.size}, modified: #{fetched_transactions.modified.size}, removed: #{fetched_transactions.removed.size})"
        PlaidItem.transaction do
          internal_plaid_accounts.each do |internal_plaid_account|
            added = fetched_transactions.added.select { |t| t.account_id == internal_plaid_account.plaid_id }
            modified = fetched_transactions.modified.select { |t| t.account_id == internal_plaid_account.plaid_id }
            removed = fetched_transactions.removed.select { |t| t.account_id == internal_plaid_account.plaid_id }

            internal_plaid_account.sync_transactions!(added:, modified:, removed:)
          end

          plaid_item.update!(next_cursor: fetched_transactions.cursor)
        end
      end

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
