class SimpleFinItem < ApplicationRecord
  include Syncable

  enum :status, { good: "good", requires_update: "requires_update" }, default: :good

  validates :institution_name, presence: true
  validates :family_id, presence: true

  belongs_to :family
  has_one_attached :logo

  has_many :simple_fin_accounts, dependent: :destroy
  has_many :accounts, through: :simple_fin_accounts

  scope :active, -> { where(scheduled_for_deletion: false) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :needs_update, -> { where(status: :requires_update) }

  class << self
    # # `provided_access_url` is the full URL from SimpleFIN (https://user:pass@beta-bridge.simplefin.org/simplefin)
    # # `connection_name` can be user-provided or derived.
    # def create_and_sync_from_access_url(provided_access_url, connection_name, family_obj)
    #   # Basic validation of the URL format
    #   uri = URI.parse(provided_access_url)
    #   raise ArgumentError, "Invalid SimpleFIN Access URL: Missing credentials" unless uri.user && uri.password
    #   raise ArgumentError, "Invalid SimpleFIN Access URL: Must be HTTPS" unless uri.scheme == "https"

    #   # Create the connection object first
    #   connection = family_obj.simple_fin_connections.create!(
    #     name: connection_name,
    #     access_url: provided_access_url,
    #     status: :good # Assume good initially
    #   )

    #   # Perform an initial sync to populate institution details and accounts
    #   connection.sync_later
    #   connection
    # end
  end

  ##
  # Syncs the simple_fin_item given and all other simple_fin accounts available (reduces calls to the API)
  def sync_data(sync, start_date: nil)
    # TODO: Rate limit
    # now = Time.current
    # # Rate Limiting Check
    # # We use a transaction here to ensure that checking the count, resetting it if needed,
    # # and incrementing it are atomic.
    # ActiveRecord::Base.transaction do
    #   # Reload self to ensure we have the latest values from the DB,
    #   # especially if this method could be called concurrently for the same item.
    #   self.reload

    #   if self.last_sync_count_reset_at.nil? || self.last_sync_count_reset_at.to_date < now.to_date
    #     # If it's a new day (or first sync ever for rate limiting), reset the count and the reset timestamp.
    #     self.update_columns(syncs_today_count: 0, last_sync_count_reset_at: now)
    #     self.reload # Reload again to get the just-updated values for the check below.
    #   end

    #   if self.syncs_today_count >= 24
    #     msg = "SimpleFinItem ID #{self.id}: Sync limit of 24 per day reached. Count: #{self.syncs_today_count}."
    #     Rails.logger.warn(msg)
    #     sync.fail!(StandardError.new(msg)) # Record failure in the Sync object
    #     raise StandardError, msg # Raise to stop execution and ensure SyncJob handles it as a failure
    #   end

    #   # If not rate-limited, increment the count for this sync attempt.
    #   self.increment!(:syncs_today_count)
    # end


    # unless access_url.present?
    #   # This is a configuration error for the connection itself.
    #   msg = "SimpleFinConnection: Sync cannot proceed for connection ID #{id}: Missing access_url."
    #   Rails.logger.error(msg)
    #   update!(status: :requires_update) # Mark connection as needing attention
    #   # Raise an error to ensure the SyncJob records this failure.
    #   # Sync#perform will catch this and call sync.fail!
    #   raise StandardError, msg
    # end

    # TODO: Populate this
    # update!(last_synced_at: Time.current, status: :requires_update)

    Rails.logger.info("SimpleFinConnection: Starting sync for connection ID #{id}")

    begin
      # Fetch all accounts for this specific connection from SimpleFIN.
      sf_accounts_data = provider.get_available_accounts(nil)


      # Keep track of external IDs reported by the provider in this sync.
      # This can be used later to identify accounts that might have been removed on the SimpleFIN side.
      current_provider_external_ids = []

      sf_accounts_data.each do |sf_account_data|
        current_provider_external_ids << sf_account_data["id"]

        begin
          # Find or create the SimpleFinAccount record.
          sfa = SimpleFinAccount.find_by(external_id: sf_account_data["id"])
        rescue StandardError
          # Ignore because it could be non existent accounts from the central sync
        end

        if sfa != nil
          # Sync the detailed data for this account (e.g., balance, and potentially transactions).
          # This method is expected to be on the SimpleFinAccount model.
          sfa.sync_account_data!(sf_account_data)
        end
      end

      # Optional: You could add logic here to handle accounts that exist in your DB for this
      # SimpleFinConnection but were NOT reported by the provider in `sf_accounts_data`.
      # These could be marked as closed, archived, etc. For example:
      # simple_fin_accounts.where.not(external_id: current_provider_external_ids).find_each(&:archive!)

      # update!(status: :good) # Mark connection as successfully synced.
      Rails.logger.info("SimpleFinConnection: Sync completed for connection ID #{id}")

    # rescue Provider::SimpleFin::AuthenticationError => e # Catch specific auth errors if your provider defines them.
    #   Rails.logger.error("SimpleFinConnection: Authentication failed for connection ID #{id}: #{e.message}")
    #   update!(status: :requires_update) # Mark the connection so the user knows to update credentials.
    #   raise e # Re-raise so Sync#perform can record the failure.
    rescue StandardError => e
      Rails.logger.error("SimpleFinConnection: Sync failed for connection ID #{id}: #{e.message}")
      update!(status: :requires_update)
      raise e # Re-raise so Sync#perform can record the failure.
    end
  end

  # def sync_data(sync, start_date: nil)
  #   update!(last_synced_at: Time.current)
  #   Rails.logger.info("SimpleFinConnection: Starting sync for connection ID #{id}")

  #   # begin
  #   #   # Fetch initial info if not present (like institution details)
  #   #   if institution_id.blank? || api_versions_supported.blank?
  #   #     info_data = provider.get_api_versions_and_org_details_from_accounts
  #   #     update!(
  #   #       institution_id: info_data[:org_id],
  #   #       institution_name: info_data[:org_name],
  #   #       institution_url: info_data[:org_url],
  #   #       institution_domain: info_data[:org_domain],
  #   #       api_versions_supported: info_data[:versions]
  #   #     )
  #   #   end

  #   #   sf_accounts_data = provider.get_available_accounts(nil) # Pass nil to get all types

  #   #   sf_accounts_data.each do |sf_account_data|
  #   #     accountable_klass_name = Provider::SimpleFin::ACCOUNTABLE_TYPE_MAPPING.find { |key, _val| sf_account_data["type"]&.downcase == key.downcase }&.last
  #   #     accountable_klass_name ||= (sf_account_data["balance"].to_d >= 0 ? Depository : CreditCard) # Basic fallback
  #   #     accountable_klass = accountable_klass_name

  #   #     sfa = simple_fin_accounts.find_or_create_from_simple_fin_data!(sf_account_data, self, accountable_klass)
  #   #     sfa.sync_account_data!(sf_account_data)
  #   #   end

  #   update!(status: :good) if requires_update?
  #   Rails.logger.info("SimpleFinConnection: Sync completed for connection ID #{id}")

  #   # rescue StandardError => e
  #   #   Rails.logger.error("SimpleFinConnection: Sync failed for connection ID #{id}: #{e.message}")
  #   #   update!(status: :requires_update)
  #   #   raise e
  #   # end
  # end

  def provider
    @provider ||= Provider::Registry.get_provider(:simple_fin)
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end
end
