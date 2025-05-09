# frozen_string_literal: true

class SimpleFinController < ApplicationController
  before_action :set_accountable_type
  before_action :authenticate_user!
  before_action :set_simple_fin_provider
  before_action :require_simple_fin_provider

  def new
    @simple_fin_accounts = @simple_fin_provider.get_available_accounts(@accountable_type)
    # Filter accounts we already have
    @simple_fin_accounts = @simple_fin_accounts.filter { |acc| !account_exists(acc) }
  rescue StandardError => e
    Rails.logger.error "SimpleFIN: Failed to fetch accounts - #{e.message}"
    redirect_to new_account_path, alert: t(".fetch_failed")
  end

  ##
  # Returns if an account exists for this family and this ID
  def account_exists(acc)
    Current.family.accounts.find_by(name: acc["name"])
  end


  ##
  # Starts a sync across all SimpleFIN accounts
  def sync
    puts "Should sync"
  end

  def create
    selected_ids = params[:selected_account_ids]
    if selected_ids.blank?
      Rails.logger.error "No accounts were selected."
      redirect_to new_simple_fin_connection_path(accountable_type: @accountable_type)
      return
    end

    all_available_accounts = @simple_fin_provider.get_available_accounts(@accountable_type)
    accounts_to_create_details = all_available_accounts.filter { |acc| selected_ids.include?(acc["id"]) }

    # Group selected accounts by their institution ID (org.id)
    accounts_by_institution = accounts_to_create_details.group_by { |acc| acc.dig("org", "id") }

    accounts_by_institution.each do |institution_id, sf_accounts_for_institution|
      first_sf_account = sf_accounts_for_institution.first # Use data from the first account for connection details
      org_details = first_sf_account["org"]

      # Find or Create the SimpleFinConnection for this institution
      simple_fin_connection = Current.family.simple_fin_connections.find_or_create_by!(institution_id: institution_id) do |sfc|
        sfc.name = org_details["name"] || "SimpleFIN Connection"
        sfc.institution_name = org_details["name"]
        sfc.institution_url = org_details["url"]
        sfc.institution_domain = org_details["domain"]
        sfc.last_synced_at = Time.current # Mark as synced upon creation
      end

      sf_accounts_for_institution.each do |acc_detail|
        next if simple_fin_connection.simple_fin_accounts.exists?(external_id: acc_detail["id"])
        next if account_exists(acc_detail)

        # Get sub type for this account from params
        sub_type = params[:account][acc_detail["id"]]["subtype"]
        acc_detail["subtype"] = sub_type


        # Create SimpleFinAccount and its associated Account
        SimpleFinAccount.find_or_create_from_simple_fin_data!(
          acc_detail,
          simple_fin_connection
        )

        # Optionally, trigger an initial sync for the new account if needed,
        # though find_or_create_from_simple_fin_data! already populates it.
        # simple_fin_account.sync_account_data!(acc_detail)

        # The Account record is created via accepts_nested_attributes_for in SimpleFinAccount
        # or by the logic within find_or_create_from_simple_fin_data!
      end
    end

    redirect_to root_path, notice: t(".accounts_created_success")
  rescue StandardError => e
    Rails.logger.error "SimpleFIN: Failed to create accounts - #{e.message}"
    redirect_to new_simple_fin_connection_path
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
