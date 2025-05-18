class SimpleFinItem::Syncer
  attr_reader :simple_fin_item

  def initialize(simple_fin_item)
    @simple_fin_item = simple_fin_item
    @provider ||= Provider::Registry.get_provider(:simple_fin)
  end

  def perform_sync(sync)
    Rails.logger.info("Starting sync for all SimpleFIN accounts")

    begin
      # Fetch all accounts for this specific connection from SimpleFIN.
      sf_accounts_data = @provider.get_available_accounts(nil)
      # Iterate over every account and attempt to apply transactions where possible
      sf_accounts_data.each do |sf_account_data|
        begin
          # Find or create the SimpleFinAccount record.
          sfa = SimpleFinAccount.find_by(external_id: sf_account_data["id"])
        rescue StandardError
          # Ignore because it could be non existent accounts from the central sync
        end

        if sfa != nil
          begin
            # Sync the detailed data for this account
            sfa.sync_account_data!(sf_account_data)
          rescue StandardError => e
            Rails.logger.error("Sync failed for account #{sf_account_data["id"]}: #{e.message}")
            sfa.simple_fin_item.update(id: sf_account_data["id"], status: :requires_update) # We had problems so make sure this account knows
          end
        end
      end

      Rails.logger.info("Sync completed for all accounts")

    rescue Provider::SimpleFin::RateLimitExceededError =>e
      Rails.logger.error("Sync failed: #{e.message}")
      raise StandardError, "SimpleFIN Rate Limit: #{e.message}" # Re-raise as a generic StandardError
    rescue StandardError => e
      Rails.logger.error("Sync failed: #{e.message}")
      raise e # Re-raise so Sync#perform can record the failure.
    end
  end

  def perform_post_sync
    simple_fin_item.auto_match_categories!
  end

  private
end
