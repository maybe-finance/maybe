module PlaidToken
  extend ActiveSupport::Concern

  included do
    before_action :set_plaid_link_token
  end

  def set_plaid_link_token
    # If current_user is present and plaid_link_token_expires_at is in the past,
    # return create a new token
    if current_user.present? && ((current_user.plaid_link_token_expires_at.present? && current_user.plaid_link_token_expires_at < Time.now) or current_user.plaid_link_token_expires_at.nil?)
      user = current_user
      client_user_id = user.id

      # Create the link_token with all of your configurations
      link_token_create_request = Plaid::LinkTokenCreateRequest.new({
        :user => { :client_user_id => client_user_id.to_s },
        :client_name => 'Maybe',
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

      user.plaid_link_token = link_token
      user.plaid_link_token_expires_at = Time.now + 3.hour
      user.save!
    end
  end
end


