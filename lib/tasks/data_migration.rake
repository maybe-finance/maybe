namespace :data_migration do
  desc "Migrate EU Plaid webhooks"
  # 2025-02-07: EU Plaid items need to be moved over to a new webhook URL so that we can
  # instantiate the correct Plaid client for verification based on which Plaid instance it comes from
  task eu_plaid_webhooks: :environment do
    provider = Provider::Plaid.new(Rails.application.config.plaid_eu, region: :eu)

    eu_items = PlaidItem.where(plaid_region: "eu")

    eu_items.find_each do |item|
      request = Plaid::ItemWebhookUpdateRequest.new(
        access_token: item.access_token,
        webhook: "https://app.maybefinance.com/webhooks/plaid_eu"
      )

      provider.client.item_webhook_update(request)

      puts "Updated webhook for Plaid item #{item.plaid_id}"
    rescue => error
      puts "Error updating webhook for Plaid item #{item.plaid_id}: #{error.message}"
    end
  end

  desc "Migrate duplicate securities"
  # 2025-05-22: older data allowed multiple rows with the same
  # ticker / exchange_operating_mic (case-insensitive, NULLs collapsed).
  # This task:
  #   1. Finds each duplicate group
  #   2. Chooses the earliest-created row as the keeper
  #   3. Re-points holdings and trades to the keeper
  #   4. Destroys the duplicate (which also removes its prices)
  task migrate_duplicate_securities: :environment do
    puts "==> Scanning for duplicate securities…"

    duplicate_sets = Security
      .select("UPPER(ticker) AS up_ticker,
               COALESCE(UPPER(exchange_operating_mic), '') AS up_mic,
               COUNT(*) AS dup_count")
      .group("up_ticker, up_mic")
      .having("COUNT(*) > 1")
      .to_a

    puts "Found #{duplicate_sets.size} duplicate groups."

    duplicate_sets.each_with_index do |set, idx|
      # Fetch duplicates ordered by creation; the first row becomes keeper
      duplicates_scope = Security
                           .where("UPPER(ticker) = ? AND COALESCE(UPPER(exchange_operating_mic), '') = ?",
                                  set.up_ticker, set.up_mic)
                           .order(:created_at)

      keeper = duplicates_scope.first
      next unless keeper

      duplicates = duplicates_scope.offset(1)

      dup_ids    = duplicates.ids

      # Skip if nothing to merge (defensive; shouldn't occur)
      next if dup_ids.empty?

      begin
        ActiveRecord::Base.transaction do
          # --------------------------------------------------------------
          # HOLDINGS
          # --------------------------------------------------------------
          holdings_moved   = 0
          holdings_deleted = 0

          dup_ids.each do |dup_id|
            Holding.where(security_id: dup_id).find_each(batch_size: 1_000) do |holding|
              # Will this holding collide with an existing keeper row?
              conflict_exists = Holding.where(
                account_id: holding.account_id,
                security_id: keeper.id,
                date:        holding.date,
                currency:    holding.currency
              ).exists?

              if conflict_exists
                holding.destroy!
                holdings_deleted += 1
              else
                holding.update!(security_id: keeper.id)
                holdings_moved += 1
              end
            end
          end

          # --------------------------------------------------------------
          # TRADES — no uniqueness constraints -> bulk update is fine
          # --------------------------------------------------------------
          trades_moved = Trade.where(security_id: dup_ids).update_all(security_id: keeper.id)

          # Ensure no rows remain pointing at duplicates before deletion
          raise "Leftover holdings detected" if Holding.where(security_id: dup_ids).exists?
          raise "Leftover trades detected"   if Trade.where(security_id: dup_ids).exists?

          duplicates.each(&:destroy!)   # destroys its security_prices via dependent: :destroy

          # Log inside the transaction so counters are in-scope
          total_holdings = holdings_moved + holdings_deleted
          puts "[#{idx + 1}/#{duplicate_sets.size}] Merged #{dup_ids.join(', ')} → #{keeper.id} " \
               "(#{total_holdings} holdings → #{holdings_moved} moved, #{holdings_deleted} removed, " \
               "#{trades_moved} trades)"
        end
      rescue => e
        puts "ERROR migrating #{dup_ids.join(', ')}: #{e.message}"
      end
    end

    puts "✅  Duplicate security migration complete."
  end
end
