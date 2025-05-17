# frozen_string_literal: true

class SimpleFinController < ApplicationController
  before_action :set_accountable_type
  before_action :authenticate_user!
  before_action :set_simple_fin_provider, only: %i[create new accounts_list]
  before_action :require_simple_fin_provider, only: %i[create new accounts_list]

  def new
    # This action now simply renders the view, which will trigger the Turbo Frame load.
  end

  ##
  # Returns if an account exists for this family and this ID
  def account_exists(acc)
    Current.family.accounts.find_by(name: acc["name"])
  end

  def accounts_list
    simple_fin_accounts_data = @simple_fin_provider.get_available_accounts(@accountable_type)
    # Filter accounts we already have
    @simple_fin_accounts = simple_fin_accounts_data.filter { |acc| !account_exists(acc) }
    # Implicitly renders app/views/simple_fin/accounts_list.html.erb
  rescue Provider::SimpleFin::RateLimitExceededError => e
    @error_message = t("simple_fin.new.rate_limit_hit")
    # Implicitly renders app/views/simple_fin/accounts_list.html.erb
    render :accounts_list # Or just let it render implicitly
  rescue StandardError => e
    Rails.logger.error "SimpleFIN: Failed to fetch accounts from accounts_list - #{e.message}"
    @error_message = t("simple_fin.new.fetch_failed")
    # Implicitly renders app/views/simple_fin/accounts_list.html.erb
    render :accounts_list # Or just let it render implicitly
  end


  ##
  # Requests all accounts to be re-synced
  def sync
    @simple_fin_item = Current.family.simple_fin_items.find(params[:id])
    unless @simple_fin_item.syncing?
      @simple_fin_item.sync_later
    end

    respond_to do |format|
      format.html { redirect_back_or_to accounts_path }
      format.json { head :ok }
    end
  end

  def create
    selected_ids = params[:selected_account_ids]
    if selected_ids.blank?
      Rails.logger.error "No accounts were selected."
      redirect_to root_path, alert: t(".no_acc_selected")
      return
    end

    all_available_accounts = @simple_fin_provider.get_available_accounts(@accountable_type)
    accounts_to_create_details = all_available_accounts.filter { |acc| selected_ids.include?(acc["id"]) }

    # Group selected accounts by their institution ID (org.id)
    accounts_by_institution = accounts_to_create_details.group_by { |acc| acc.dig("org", "id") }

    accounts_by_institution.each do |institution_id, sf_accounts_for_institution|
      first_sf_account = sf_accounts_for_institution.first # Use data from the first account for connection details
      org_details = first_sf_account["org"]

      # Find or Create the SimpleFinItem for this institution
      simple_fin_item = Current.family.simple_fin_items.find_or_create_by!(institution_id: institution_id) do |sfc|
        sfc.institution_name = org_details["name"]
        sfc.institution_url = org_details["url"]
        sfc.institution_domain = org_details["domain"]
      end

      sf_accounts_for_institution.each do |acc_detail|
        next if simple_fin_item.simple_fin_accounts.exists?(external_id: acc_detail["id"])
        next if account_exists(acc_detail)

        # Get sub type for this account from params
        sub_type = params.dig(:account, acc_detail["id"], :subtype)
        acc_detail["subtype"] = sub_type


        # Create SimpleFinAccount and its associated Account
        simple_fin_account = SimpleFinAccount.find_or_create_from_simple_fin_data!(
          acc_detail,
          simple_fin_item
        )
        # Trigger an account sync of our data
        simple_fin_account.sync_account_data!(acc_detail)
      end
    end

    redirect_to root_path, notice: t(".accounts_created_success")
  rescue Provider::SimpleFin::RateLimitExceededError => e
    redirect_to new_account_path, alert: t(".rate_limit_hit")
  rescue StandardError => e
    Rails.logger.error "SimpleFIN: Failed to create accounts - #{e.message}"
    redirect_to new_simple_fin_path
  end

  private
    def set_accountable_type
      @accountable_type = params[:accountable_type]
    end

    def set_simple_fin_provider
      @simple_fin_provider = Provider::Registry.get_provider(:simple_fin)
    end

    def require_simple_fin_provider
      unless @simple_fin_provider&.is_available(Current.user.id, @accountable_type)
        redirect_to new_account_path
      end
    end
end
