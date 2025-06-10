class PlaidItem < ApplicationRecord
  include Syncable, Provided

  enum :plaid_region, { us: "us", eu: "eu" }
  enum :status, { good: "good", requires_update: "requires_update" }, default: :good

  if Rails.application.credentials.active_record_encryption.present?
    encrypts :access_token, deterministic: true
  end

  validates :name, :access_token, presence: true

  before_destroy :remove_plaid_item

  belongs_to :family
  has_one_attached :logo

  has_many :plaid_accounts, dependent: :destroy
  has_many :accounts, through: :plaid_accounts

  scope :active, -> { where(scheduled_for_deletion: false) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :needs_update, -> { where(status: :requires_update) }

  def get_update_link_token(webhooks_url:, redirect_url:)
    family.get_link_token(
      webhooks_url: webhooks_url,
      redirect_url: redirect_url,
      region: plaid_region,
      access_token: access_token
    )
  rescue Plaid::ApiError => e
    error_body = JSON.parse(e.response_body)

    if error_body["error_code"] == "ITEM_NOT_FOUND"
      # Mark the connection as invalid but don't auto-delete
      update!(status: :requires_update)
    end

    Sentry.capture_exception(e)
    nil
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end

  def import_latest_plaid_data
    PlaidItem::Importer.new(self, plaid_provider: plaid_provider).import
  end

  # Reads the fetched data and updates internal domain objects
  # Generally, this should only be called within a "sync", but can be called
  # manually to "re-sync" the already fetched data
  def process_accounts
    plaid_accounts.each do |plaid_account|
      PlaidAccount::Processor.new(plaid_account).process
    end
  end

  # Once all the data is fetched, we can schedule account syncs to calculate historical balances
  def schedule_account_syncs(parent_sync: nil, window_start_date: nil, window_end_date: nil)
    accounts.each do |account|
      account.sync_later(
        parent_sync: parent_sync,
        window_start_date: window_start_date,
        window_end_date: window_end_date
      )
    end
  end

  # Saves the raw data fetched from Plaid API for this item
  def upsert_plaid_snapshot!(item_snapshot)
    assign_attributes(
      available_products: item_snapshot.available_products,
      billed_products: item_snapshot.billed_products,
      raw_payload: item_snapshot,
    )

    save!
  end

  # Saves the raw data fetched from Plaid API for this item's institution
  def upsert_plaid_institution_snapshot!(institution_snapshot)
    assign_attributes(
      institution_id: institution_snapshot.institution_id,
      institution_url: institution_snapshot.url,
      institution_color: institution_snapshot.primary_color,
      raw_institution_payload: institution_snapshot
    )

    save!
  end

  def supports_product?(product)
    supported_products.include?(product)
  end

  private
    def remove_plaid_item
      plaid_provider.remove_item(access_token)
    rescue Plaid::ApiError => e
      json_response = JSON.parse(e.response_body)

      # If the item is not found, that means it was already deleted by the user on their
      # Plaid portal OR by Plaid support.  Either way, we're not being billed, so continue
      # with the deletion of our internal record.
      unless json_response["error_code"] == "ITEM_NOT_FOUND"
        raise e
      end
    end

    # Plaid returns mutually exclusive arrays here.  If the item has made a request for a product,
    # it is put in the billed_products array.  If it is supported, but not yet used, it goes in the
    # available_products array.
    def supported_products
      available_products + billed_products
    end
end
