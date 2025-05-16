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

  ##
  # Syncs the simple_fin_item given and all other simple_fin accounts available (reduces calls to the API)
  def sync_data(sync, start_date: nil)
    Rails.logger.info("SimpleFINItem: Starting sync for all SimpleFIN accounts")

    begin
      # Fetch all accounts for this specific connection from SimpleFIN.
      sf_accounts_data = provider.get_available_accounts(nil)
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
            Rails.logger.error("SimpleFINItem: Sync failed for account #{sf_account_data["id"]}: #{e.message}")
            sfa.simple_fin_item.update(id: sf_account_data["id"], status: :requires_update) # We had problems so make sure this account knows
          end
        end
      end

      Rails.logger.info("SimpleFINItem: Sync completed for all accounts")

    rescue Provider::SimpleFin::RateLimitExceededError =>e
      Rails.logger.error("SimpleFINItem: Sync failed: #{e.message}")
      raise StandardError, "SimpleFIN Rate Limit: #{e.message}" # Re-raise as a generic StandardError
    rescue StandardError => e
      Rails.logger.error("SimpleFINItem: Sync failed: #{e.message}")
      raise e # Re-raise so Sync#perform can record the failure.
    end
  end

  def provider
    @provider ||= Provider::Registry.get_provider(:simple_fin)
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end
end
