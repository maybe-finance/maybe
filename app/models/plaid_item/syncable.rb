module PlaidItem::Syncable
  extend ActiveSupport::Concern

  include Syncable

  def sync_data(sync, start_date: nil)
    begin
      Rails.logger.info("Fetching and loading Plaid data")
      fetch_and_load_plaid_data(sync)
      update!(status: :good) if requires_update?

      # Schedule account syncs
      accounts.each do |account|
        account.sync_later(start_date: start_date, parent_sync: sync)
      end

      Rails.logger.info("Plaid data fetched and loaded")
    rescue Plaid::ApiError => e
      handle_plaid_error(e)
      raise e
    end
  end

  def post_sync(sync)
    auto_match_categories!
    family.broadcast_refresh
  end
end
