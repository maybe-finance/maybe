# frozen_string_literal: true

class Api::V1::AccountsController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization for read access
  before_action :ensure_read_scope

  def index
    # Test with Pagy pagination
    family = current_resource_owner.family
    accounts_query = family.accounts.active.alphabetically

    # Handle pagination with Pagy
    @pagy, @accounts = pagy(
      accounts_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    render json: {
      accounts: serialize_accounts(@accounts),
      pagination: {
        page: @pagy.page,
        per_page: safe_per_page_param,
        total_count: @pagy.count,
        total_pages: @pagy.pages
      }
    }
  rescue => e
    Rails.logger.error "AccountsController error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

    private

      def ensure_read_scope
        authorize_scope!(:read)
      end

      def serialize_accounts(accounts)
        accounts.map do |account|
          {
            id: account.id,
            name: account.name,
            balance: account.balance_money.format,
            currency: account.currency,
            classification: account.classification,
            account_type: account.accountable_type.underscore,
            subtype: account.subtype,
            is_active: account.is_active,
            created_at: account.created_at.iso8601,
            updated_at: account.updated_at.iso8601
          }
        end
      end

      def safe_page_param
        page = params[:page].to_i
        page > 0 ? page : 1
      end

      def safe_per_page_param
        per_page = params[:per_page].to_i

        # Default to 25, max 100
        case per_page
        when 1..100
          per_page
        else
          25
        end
      end
end
