class Family < ApplicationRecord
  include Providable, Plaidable, Syncable, AutoTransferMatchable

  DATE_FORMATS = [
    [ "MM-DD-YYYY", "%m-%d-%Y" ],
    [ "DD.MM.YYYY", "%d.%m.%Y" ],
    [ "DD-MM-YYYY", "%d-%m-%Y" ],
    [ "YYYY-MM-DD", "%Y-%m-%d" ],
    [ "DD/MM/YYYY", "%d/%m/%Y" ],
    [ "YYYY/MM/DD", "%Y/%m/%d" ],
    [ "MM/DD/YYYY", "%m/%d/%Y" ],
    [ "D/MM/YYYY", "%e/%m/%Y" ],
    [ "YYYY.MM.DD", "%Y.%m.%d" ]
  ].freeze

  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :plaid_items, dependent: :destroy
  has_many :invitations, dependent: :destroy

  has_many :imports, dependent: :destroy
  has_many :issues, through: :accounts

  has_many :entries, through: :accounts
  has_many :transactions, through: :accounts
  has_many :trades, through: :accounts
  has_many :holdings, through: :accounts

  has_many :tags, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :merchants, dependent: :destroy

  has_many :budgets, dependent: :destroy
  has_many :budget_categories, through: :budgets

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :date_format, inclusion: { in: DATE_FORMATS.map(&:last) }

  def balance_sheet
    @balance_sheet ||= BalanceSheet.new(self)
  end

  def income_statement
    @income_statement ||= IncomeStatement.new(self)
  end

  def sync_data(start_date: nil)
    update!(last_synced_at: Time.current)

    accounts.manual.each do |account|
      account.sync_later(start_date: start_date)
    end

    plaid_items.each do |plaid_item|
      plaid_item.sync_later(start_date: start_date)
    end
  end

  def post_sync
    broadcast_refresh
  end

  def syncing?
    Sync.where(
      "(syncable_type = 'Family' AND syncable_id = ?) OR
       (syncable_type = 'Account' AND syncable_id IN (SELECT id FROM accounts WHERE family_id = ? AND plaid_account_id IS NULL)) OR
       (syncable_type = 'PlaidItem' AND syncable_id IN (SELECT id FROM plaid_items WHERE family_id = ?))",
      id, id, id
    ).where(status: [ "pending", "syncing" ]).exists?
  end

  def eu?
    country != "US" && country != "CA"
  end

  def get_link_token(webhooks_url:, redirect_url:, accountable_type: nil, region: :us, access_token: nil)
    provider = if region.to_sym == :eu
      self.class.plaid_eu_provider
    else
      self.class.plaid_us_provider
    end

    # early return when no provider
    return nil unless provider

    provider.get_link_token(
      user_id: id,
      webhooks_url: webhooks_url,
      redirect_url: redirect_url,
      accountable_type: accountable_type,
      access_token: access_token
    ).link_token
  end

  def synth_usage
    self.class.synth_provider&.usage
  end

  def synth_overage?
    self.class.synth_provider&.usage&.utilization.to_i >= 100
  end

  def synth_valid?
    self.class.synth_provider&.healthy?
  end

  def subscribed?
    stripe_subscription_status == "active"
  end

  def primary_user
    users.order(:created_at).first
  end

  def oldest_entry_date
    entries.order(:date).first&.date || Date.current
  end

  def active_accounts_count
    accounts.active.count
  end
end
