class PlaidItem::AccountsImporter
  def initialize(plaid_item)
    @plaid_item = plaid_item
  end

  def import
    raw_accounts_data = plaid_provider.get_item_accounts(plaid_item).accounts

    raw_accounts_data.each do |raw_account_data|
      PlaidAccount.transaction do
        plaid_account = plaid_item.plaid_accounts.find_or_initialize_by(
          plaid_id: raw_account_data.account_id
        )

        plaid_account.current_balance = raw_account_data.balances.current
        plaid_account.available_balance = raw_account_data.balances.available
        plaid_account.currency = raw_account_data.balances.iso_currency_code
        plaid_account.plaid_type = raw_account_data.type
        plaid_account.plaid_subtype = raw_account_data.subtype

        # Save raw payload for audit trail
        plaid_account.raw_payload = raw_account_data.to_h

        plaid_account.save!
      end
    end
  end

  private
    attr_reader :plaid_item

    def plaid_provider
      plaid_item.plaid_provider
    end
end
