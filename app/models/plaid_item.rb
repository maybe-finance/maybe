class PlaidItem < ApplicationRecord
  include Syncable

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
    begin
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
        raise PlaidConnectionLostError
      else
        raise e
      end
    end
  end

  def build_category_alias_matcher(user_categories)
    Provider::Plaid::CategoryAliasMatcher.new(user_categories)
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end

  def syncing?
    Sync.joins("LEFT JOIN accounts a ON a.id = syncs.syncable_id AND syncs.syncable_type = 'Account'")
        .joins("LEFT JOIN plaid_accounts pa ON pa.id = a.plaid_account_id")
        .where("syncs.syncable_id = ? OR pa.plaid_item_id = ?", id, id)
        .visible
        .exists?
  end

  def auto_match_categories!
    if family.categories.none?
      family.categories.bootstrap!
    end

    alias_matcher = build_category_alias_matcher(family.categories)

    accounts.each do |account|
      matchable_transactions = account.transactions
                                      .where(category_id: nil)
                                      .where.not(plaid_category: nil)
                                      .enrichable(:category_id)

      matchable_transactions.each do |transaction|
        category = alias_matcher.match(transaction.plaid_category_detailed)

        if category.present?
          # Matcher could either return a string or a Category object
          user_category = if category.is_a?(String)
            family.categories.find_or_create_by!(name: category)
          else
            category
          end

          transaction.enrich_attribute(:category_id, user_category.id, source: "plaid")
        end
      end
    end
  end

  private
    def remove_plaid_item
      plaid_provider.remove_item(access_token)
    rescue StandardError => e
      Rails.logger.warn("Failed to remove Plaid item #{id}: #{e.message}")
    end

    class PlaidConnectionLostError < StandardError; end
end
