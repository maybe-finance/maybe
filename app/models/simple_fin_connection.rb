class SimpleFinConnection < ApplicationRecord
  include Syncable

  enum :status, { good: "good", requires_update: "requires_update" }, default: :good

  validates :name, presence: true
  validates :family_id, presence: true

  belongs_to :family
  has_one_attached :logo

  has_many :simple_fin_accounts, dependent: :destroy
  has_many :accounts, through: :simple_fin_accounts

  scope :active, -> { where(scheduled_for_deletion: false) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :needs_update, -> { where(status: :requires_update) }

  class << self
    # `provided_access_url` is the full URL from SimpleFIN (https://user:pass@beta-bridge.simplefin.org/simplefin)
    # `connection_name` can be user-provided or derived.
    def create_and_sync_from_access_url(provided_access_url, connection_name, family_obj)
      # Basic validation of the URL format
      uri = URI.parse(provided_access_url)
      raise ArgumentError, "Invalid SimpleFIN Access URL: Missing credentials" unless uri.user && uri.password
      raise ArgumentError, "Invalid SimpleFIN Access URL: Must be HTTPS" unless uri.scheme == "https"

      # Create the connection object first
      connection = family_obj.simple_fin_connections.create!(
        name: connection_name,
        access_url: provided_access_url,
        status: :good # Assume good initially
      )

      # Perform an initial sync to populate institution details and accounts
      connection.sync_later
      connection
    end
  end

  def sync_data(sync, start_date: nil)
    update!(last_synced_at: Time.current)
    Rails.logger.info("SimpleFinConnection: Starting sync for connection ID #{id}")

    begin
      # Fetch initial info if not present (like institution details)
      if institution_id.blank? || api_versions_supported.blank?
        info_data = provider.get_api_versions_and_org_details_from_accounts
        update!(
          institution_id: info_data[:org_id],
          institution_name: info_data[:org_name],
          institution_url: info_data[:org_url],
          institution_domain: info_data[:org_domain],
          api_versions_supported: info_data[:versions]
        )
      end

      sf_accounts_data = provider.get_available_accounts(nil) # Pass nil to get all types

      sf_accounts_data.each do |sf_account_data|
        accountable_klass_name = Provider::SimpleFin::ACCOUNTABLE_TYPE_MAPPING.find { |key, _val| sf_account_data["type"]&.downcase == key.downcase }&.last
        accountable_klass_name ||= (sf_account_data["balance"].to_d >= 0 ? Depository : CreditCard) # Basic fallback
        accountable_klass = accountable_klass_name

        sfa = simple_fin_accounts.find_or_create_from_simple_fin_data!(sf_account_data, self, accountable_klass)
        sfa.sync_account_data!(sf_account_data)
      end

      update!(status: :good) if requires_update?
      Rails.logger.info("SimpleFinConnection: Sync completed for connection ID #{id}")

    rescue StandardError => e
      Rails.logger.error("SimpleFinConnection: Sync failed for connection ID #{id}: #{e.message}")
      update!(status: :requires_update)
      raise e
    end
  end

  def provider
    @provider ||= Provider::SimpleFin.new()
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end
end
