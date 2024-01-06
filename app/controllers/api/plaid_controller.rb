class Api::PlaidController < ApplicationController
  skip_before_action :verify_authenticity_token

  def exchange_public_token
    public_token = params[:public_token]

    exchange_token_request = Plaid::ItemPublicTokenExchangeRequest.new({
      :public_token => public_token
    })

    exchange_token_response = $plaid_api_client.item_public_token_exchange(
      exchange_token_request
    )

    access_token = exchange_token_response.access_token
    item_id = exchange_token_response.item_id

    item_get_request = Plaid::ItemGetRequest.new({ access_token: access_token})
    item_response = $plaid_api_client.item_get(item_get_request)
    aggregator_id = item_response.item.institution_id
    consent_expiration = item_response.item.consent_expiration_time

    institutions_get_by_id_request = Plaid::InstitutionsGetByIdRequest.new(
      {
        institution_id: item_response.item.institution_id,
        country_codes: ['US', 'CA']
      }
    )
    institution_response = $plaid_api_client.institutions_get_by_id(institutions_get_by_id_request)

    user = current_user

    user.connections.find_or_initialize_by(source: 'plaid', item_id: item_id).update(
      access_token: access_token,
      aggregator_id: aggregator_id,
      consent_expiration: consent_expiration,
      name: institution_response.institution.name,
      status: 'ok',
      error: nil,
      family: user.family
    )
    user.save!

    SyncPlaidItemAccountsJob.perform(item_id)

    # SyncPlaidHoldingsJob.perform(item_id)
    # SyncPlaidInvestmentTransactionsJob.perform(item_id)

    GenerateMetricsJob.perform_in(1.minute, user.family.id)

    render json: {
      status: 200,
      message: 'Successfully exchanged public token for access token',
      access_token: access_token,
      item_id: item_id
    }
  end
end
