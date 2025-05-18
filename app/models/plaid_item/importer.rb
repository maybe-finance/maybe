class PlaidItem::Importer
  def initialize(plaid_item)
    @plaid_item = plaid_item
  end

  def import_data
    begin
      import_item_metadata
    rescue Plaid::ApiError => e
      handle_plaid_error(e)
    end

    import_accounts
    import_transactions if plaid_item.transactions_enabled?
    import_investments if plaid_item.investments_enabled?
    import_liabilities if plaid_item.liabilities_enabled?
  end

  private
    attr_reader :plaid_item

    def plaid_provider
      plaid_item.plaid_provider
    end

    def import_item_metadata
      raw_item_data = plaid_provider.get_item(plaid_item.access_token)
      plaid_item.update!(
        available_products: raw_item_data.available_products,
        billed_products: raw_item_data.billed_products
      )
    end

    # Re-raise all errors that should halt data importing.  Raising will propagate to
    # the sync and mark it as failed.
    def handle_plaid_error(error)
      error_body = JSON.parse(error.response_body)

      case error_body["error_code"]
      when "ITEM_LOGIN_REQUIRED"
        plaid_item.update!(status: :requires_update)
        raise error
      else
        raise error
      end
    end

    def import_accounts
      PlaidItem::AccountsImporter.new(plaid_item).import
    end

    def import_transactions
      PlaidItem::TransactionsImporter.new(plaid_item).import
    end

    def import_investments
      PlaidItem::InvestmentsImporter.new(plaid_item).import
    end

    def import_liabilities
      PlaidItem::LiabilitiesImporter.new(plaid_item).import
    end
end
