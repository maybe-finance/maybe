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

  def provider
    @provider ||= Provider::Registry.get_provider(:simple_fin)
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end

  def syncing?
    Sync.joins("LEFT JOIN accounts a ON a.id = syncs.syncable_id AND syncs.syncable_type = 'Account'")
        .joins("LEFT JOIN simple_fin_accounts sfa ON sfa.id = a.simple_fin_account_id")
        .where("syncs.syncable_id = ? OR sfa.simple_fin_item_id = ?", id, id)
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
                                      .where.not(simple_fin_category: nil)
                                      .enrichable(:category_id)

      matchable_transactions.each do |transaction|
        category = alias_matcher.match(transaction.simple_fin_category)

        if category.present?
          SimpleFinItem.transaction do
            transaction.log_enrichment!(
              attribute_name: "category_id",
              attribute_value: category.id,
              source: "simple_fin"
            )
            transaction.set_category!(category)
          end
        end
      end
    end
  end
end
