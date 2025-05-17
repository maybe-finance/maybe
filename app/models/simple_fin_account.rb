class SimpleFinAccount < ApplicationRecord
  TYPE_MAPPING = {
    "Depository" => Depository,
    "CreditCard" => CreditCard,
    "Loan" => Loan,
    "Investment" => Investment,
    "Other" => OtherAsset
  }

  belongs_to :simple_fin_item
  has_one :account, dependent: :destroy, foreign_key: :simple_fin_account_id, inverse_of: :simple_fin_account

  accepts_nested_attributes_for :account

  validates :external_id, presence: true, uniqueness: true
  validates :simple_fin_item_id, presence: true

  after_destroy :cleanup_connection_if_orphaned


  class << self
    # Gets what balance we should use as our account balance
    def get_adjusted_balance(sf_account_data)
      balance_from_sf = sf_account_data["balance"].to_d
      account_type = sf_account_data["type"]
      # Adjust balance: liabilities (CreditCard, Loan) should be negative
      if [ "CreditCard", "Loan" ].include?(account_type)
        balance_from_sf * -1
      else
        balance_from_sf
      end
    end

    def find_or_create_from_simple_fin_data!(sf_account_data, sfc)
      sfc.simple_fin_accounts.find_or_create_by!(external_id: sf_account_data["id"]) do |sfa|
        balance = get_adjusted_balance(sf_account_data)
        sfa.current_balance = balance
        sfa.available_balance = sf_account_data["available-balance"]&.to_d
        sfa.currency = sf_account_data["currency"]


        if sfa.account
          account = sfa.account
        else
          sfa.account = sfc.family.accounts.new(
            name: sf_account_data["name"],
            balance: sfa.current_balance,
            currency: sf_account_data["currency"],
            accountable: TYPE_MAPPING[sf_account_data["type"]].new,
            subtype: sf_account_data["subtype"],
            simple_fin_account: sfa, # Explicitly associate back
            last_synced_at: Time.current, # Mark as synced upon creation
            # Set cash_balance similar to how Account.create_and_sync might
            cash_balance: sfa.available_balance
          )
          account = sfa.account
          account.save!

          transaction do
            # Create 2 valuations for new accounts to establish a value history for users to see
            account.entries.build(
              name: "Current Balance",
              date: Date.current,
              amount: sfa.current_balance,
              currency: account.currency,
              entryable: Valuation.new
            )
            account.entries.build(
              name: "Initial Balance",
              date: 1.day.ago.to_date,
              amount: 0,
              currency: account.currency,
              entryable: Valuation.new
            )

            account.save!
          end
        end

        # Make sure SFA is up to date
        sfa.save!
        sfa.sync_account_data!(sf_account_data)
        # Sync this account to trick it into showing a correct current balance
        account.sync_later
      end
    end


    def family
      simple_fin_item&.family
    end
  end

  ##
  # Syncs all account data for the given sf_account_data parameter
  def sync_account_data!(sf_account_data)
    balance = SimpleFinAccount.get_adjusted_balance(sf_account_data)
    puts "SFA #{sf_account_data} #{self.account.inspect}"
    self.update!(
      current_balance: balance,
      available_balance: sf_account_data["available-balance"]&.to_d
    )

    self.account.update!(
      balance: balance
    )

    institution_errors = sf_account_data["org"]["institution_errors"]

    self.simple_fin_item.update!(
      institution_errors: institution_errors.empty? ? []: institution_errors,
      status: institution_errors.empty? ? :good : :requires_update
    )

    # Sync transactions if present in the data
    if sf_account_data["transactions"].is_a?(Array)
      sync_transactions!(sf_account_data["transactions"])
    end

    # Sync holdings if present in the data and it's an investment account. SimpleFIN doesn't support transactions for holdings accounts
    if self.account&.investment? && sf_account_data["holdings"].is_a?(Array)
      sync_holdings!(sf_account_data["holdings"])
    end
  end

  # sf_holdings_data is an array of holding hashes from SimpleFIN for this specific account
  def sync_holdings!(sf_holdings_data)
    # 'account' here refers to self.account
    return unless self.account.present? && self.account.investment? && sf_holdings_data.is_a?(Array)
    Rails.logger.info "SimpleFINAccount (#{self.account.id}): Entering sync_holdings! with #{sf_holdings_data.length} items."

    # Get existing SimpleFIN holding IDs for this account to detect deletions
    existing_provider_holding_ids = self.account.holdings.where.not(simple_fin_holding_id: nil).pluck(:simple_fin_holding_id)
    current_provider_holding_ids = sf_holdings_data.map { |h_data| h_data["id"] }

    # Delete holdings that are no longer present in SimpleFIN's data
    holdings_to_delete_ids = existing_provider_holding_ids - current_provider_holding_ids
    Rails.logger.info "SimpleFINAccount (#{self.account.id}): Will delete SF holding IDs: #{holdings_to_delete_ids}"
    self.account.holdings.where(simple_fin_holding_id: holdings_to_delete_ids).destroy_all

    sf_holdings_data.each do |holding_data|
      # Find or create the Security based on the holding data
      security = find_or_create_security_from_holding_data(holding_data)
      next unless security # Skip if we can't determine a security

      Rails.logger.info "SimpleFINAccount (#{self.account.id}): Processing SF holding ID #{holding_data['id']}"
      existing_holding = self.account.holdings.find_or_initialize_by(
          security: security,
          date: Date.current,
          currency: holding_data["currency"]
        )

      existing_holding.qty = holding_data["shares"]&.to_d
      existing_holding.price = holding_data["purchase_price"]&.to_d
      existing_holding.amount = holding_data["market_value"]&.to_d
      # Cost basis is at holding level, not per share
      # existing_holding.cost_basis = holding_data["cost_basis"]&.to_d
      existing_holding.save!
    end
  end

  # sf_transactions_data is an array of transaction hashes from SimpleFIN for this specific account
  def sync_transactions!(sf_transactions_data)
    # 'account' here refers to self.account
    return unless self.account.present? && sf_transactions_data.is_a?(Array)

    sf_transactions_data.each do |transaction_data|
      entry = self.account.entries.find_or_initialize_by(simple_fin_transaction_id: transaction_data["id"])

      entry.assign_attributes(
        name: transaction_data["description"],
        amount: transaction_data["amount"].to_d,
        currency: self.account.currency,
        date: Time.at(transaction_data["posted"].to_i).to_date,
        source: "simple_fin"
      )

      entry.entryable ||= Transaction.new
      unless entry.entryable.is_a?(Transaction)
        entry.entryable = Transaction.new
      end


      entry.entryable.simple_fin_category = transaction_data.dig("extra", "category") if entry.entryable.respond_to?(:simple_fin_category=)

      # Auto associate a category to our transaction
      if entry.entryable.simple_fin_category.present?
        category_name = entry.entryable.simple_fin_category
        category = self.account.family.categories.find_or_create_by!(name: category_name)
        entry.entryable.category = category
      end


      if entry.changed? || entry.entryable.changed? # Check if entryable also changed
        entry.save!
      else
        Rails.logger.info "SimpleFINAccount (#{self.account.id}): Entry for SF transaction ID #{transaction_data['id']} not changed, not saving."
      end
    end
  end

  ##
  # Helper to find or create a Security record based on SimpleFIN holding data
  # SimpleFIN data is less detailed than Plaid securities, often just providing symbol and description.
  def find_or_create_security_from_holding_data(holding_data)
    symbol = holding_data["symbol"]&.upcase
    description = holding_data["description"]

    # We need at least a symbol or description to create/find a security
    return nil unless symbol.present? || description.present?

    # Try finding by ticker first, then by name (description) if no ticker
    Security.find_or_create_by!(ticker: symbol) do |sec|
      sec.name = description if description.present?
    end
  end

  private

    def cleanup_connection_if_orphaned
      # Reload the connection to get the most up-to-date count of associated accounts
      connection = simple_fin_item.reload
      connection.destroy_later if connection.simple_fin_accounts.empty?
    end
end
