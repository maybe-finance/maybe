class AccountsController < ApplicationController
  before_action :authenticate_user!

  def index
    # If errors, generate a new link token for the connection
    if current_family.connections.error.present?
      # For each error, generate a new link token
      @link_tokens = []
      current_family.connections.error.each do |connection|
        # Create the link_token with all of your configurations
        link_token_create_request = Plaid::LinkTokenCreateRequest.new({
          :user => { :client_user_id => connection.id.to_s },
          :client_name => 'Maybe',
          :access_token => connection.access_token,
          :products => ['transactions'],
          :country_codes => ['US', 'CA'], #, 'GB', 'DE', 'FR', 'NL', 'IE', 'ES', 'SE', 'DK'],
          :language => 'en',
          redirect_uri: ENV['PLAID_REDIRECT_URI']
        })

        link_token_response = $plaid_api_client.link_token_create(
          link_token_create_request
        )

        # Pass the result to your client-side app to initialize Link
        # and retrieve a public_token
        link_token = link_token_response.link_token

        # Add the link_token along with connection ID to the link_tokens array
        @link_tokens << { connection_id: connection.id, link_token: link_token }
      end
    end

    # Get list of all net_worth entries from metrics, order by date, limit to 30, uniq by date
    @net_worths = current_family.metrics.where(kind: 'net_worth').order(date: :asc).limit(30).uniq(&:date)

    @chart_data = {
      labels: @net_worths.map(&:date),
      datasets: [{
        label: '',
        backgroundColor: 'transparent',
        borderColor: '#34D399',
        pointStyle: false,
        borderWidth: 3,
        borderJoinStyle: 'round',
        borderCapStyle: 'round',
        data: @net_worths.map(&:amount),
      }]
    }

    @chart_options = {
      responsive: true,
      scales: {
        y: {
          beginAtZero: false,
          display: false,
          grid: {
            display: false
          }
          # ticks: {
          #     callback: function(value, index, ticks) {
          #         return '$' + value;
          #     }
          # }
        },
        x: {
          display: false,
          grid: {
            display: false
          }
        }
      },
      plugins: {
        legend: {
          display: false
        }
      }
    }
  end

  def assets
  end

  def cash
  end

  def investments
  end

  def show
  end

  def credit
  end

  def debts
  end

  def create
    # Create a new account
    @account = Account.new(account_params)
    @account.family = current_family

    # Save the account
    if @account.save
      GenerateBalanceJob.perform_async(@account.id)
      GenerateMetricsJob.perform_in(15.seconds, current_family.id)

      if @account.kind == 'property' and @account.subkind == 'real_estate'
        SyncPropertyValuesJob.perform_async(@account.id)
      end

      # If the account saved, redirect to the accounts page
      redirect_to accounts_path
    else
      # If the account didn't save, render the new account page
      render :new
    end
  end

  def new
    render layout: 'simple'
  end

  def new_bank
    render layout: 'simple'
  end

  def new_bank_manual
    # Find or create a new "Manual Bank" connection
    @connection = Connection.find_or_create_by(user: current_user, family: current_family, name: "Manual", source: "manual")
    @account = Account.new
    
    render layout: 'simple'
  end

  def new_investment
    render layout: 'simple'
  end

  def new_real_estate
    @connection = Connection.find_or_create_by(user: current_user, family: current_family, name: "Manual", source: "manual")
    @account = Account.new
    render layout: 'simple'
  end

  def new_investment_position
    @connection = Connection.find_or_create_by(user: current_user, family: current_family, name: "Manual", source: "manual")
    @account = @connection.accounts.find_or_create_by(name: "Manual", source: "manual")
    @holding = Holding.new

    render layout: 'simple'
  end

  def new_credit
    render layout: 'simple'
  end

  def new_credit_manual
    # Find or create a new "Manual Bank" connection
    @connection = Connection.find_or_create_by(user: current_user, family: current_family, name: "Manual", source: "manual")
    @account = Account.new
    
    render layout: 'simple'
  end

  private

  def account_params

    property_details = params.require(:account)[:property_details]
    parsed_property_details = property_details.nil? ? nil : JSON.parse(property_details)

    params.require(:account).permit(:name, :current_balance, :connection_id, :kind, :subkind, :currency_code, :credit_limit, :property_details, :auto_valuation, :official_name).merge(property_details: parsed_property_details)
  end
end
