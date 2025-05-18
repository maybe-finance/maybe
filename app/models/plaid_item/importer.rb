class PlaidItem::Importer
  def initialize(plaid_item, plaid_provider:)
    @plaid_item = plaid_item
    @plaid_provider = plaid_provider
  end

  def import
    import_item_metadata
    import_institution_metadata
    import_accounts
  rescue Plaid::ApiError => e
    handle_plaid_error(e)
  end

  private
    attr_reader :plaid_item, :plaid_provider

    # All errors that should halt the import should be re-raised after handling
    # These errors will propagate up to the Sync record and mark it as failed.
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

    def import_item_metadata
      item_response = plaid_provider.get_item(plaid_item.access_token)
      item_data = item_response.item

      # plaid_item.raw_payload = item_response
      plaid_item.available_products = item_data.available_products
      plaid_item.billed_products = item_data.billed_products
      plaid_item.institution_id = item_data.institution_id

      plaid_item.save!
    end

    def import_institution_metadata
      institution_response = plaid_provider.get_institution(plaid_item.institution_id)
      institution_data = institution_response.institution

      # plaid_item.raw_institution_payload = institution_response
      plaid_item.institution_id = institution_data.institution_id
      plaid_item.institution_url = institution_data.url
      plaid_item.institution_color = institution_data.primary_color

      plaid_item.save!
    end

    def import_accounts
      accounts_data = plaid_provider.get_item_accounts(plaid_item).accounts

      PlaidItem.transaction do
        accounts_data.each do |raw_account_payload|
          plaid_account = plaid_item.plaid_accounts.find_or_initialize_by(
            plaid_id: raw_account_payload.account_id
          )

          PlaidAccount::Importer.new(
            plaid_account,
            accounts_data: accounts_data,
            transactions_data: transactions_data,
            investments_data: investments_data,
            liabilities_data: liabilities_data
          ).import
        end
      end
    end

    def transactions_supported?
      plaid_item.supported_products.include?("transactions")
    end

    def investments_supported?
      plaid_item.supported_products.include?("investments")
    end

    def liabilities_supported?
      plaid_item.supported_products.include?("liabilities")
    end

    def transactions_data
      return nil unless transactions_supported?

      plaid_provider.get_item_transactions(plaid_item).transactions
    end

    def investments_data
      return nil unless investments_supported?

      plaid_provider.get_item_investments(plaid_item).investments
    end

    def liabilities_data
      return nil unless liabilities_supported?

      plaid_provider.get_item_liabilities(plaid_item).liabilities
    end
end
