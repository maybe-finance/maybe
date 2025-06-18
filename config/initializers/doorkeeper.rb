# frozen_string_literal: true

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use (requires ORM extensions installed).
  # Check the list of supported ORMs here: https://github.com/doorkeeper-gem/doorkeeper#orms
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    # Manually replicate the app's session-based authentication logic, since
    # Doorkeeper controllers don't include our Authentication concern.
    if (session_id = cookies.signed[:session_token]).present?
      if (session_record = Session.find_by(id: session_id))
        # Set Current.session so downstream code expecting it behaves normally.
        Current.session = session_record
        # Return the authenticated user object as the resource owner.
        session_record.user
      else
        redirect_to new_session_url
      end
    else
      redirect_to new_session_url
    end
  end

  # If you didn't skip applications controller from Doorkeeper routes in your application routes.rb
  # file then you need to declare this block in order to restrict access to the web interface for
  # adding oauth authorized applications. In other case it will return 403 Forbidden response
  # every time somebody will try to access the admin web interface.
  #
  admin_authenticator do
    if (session_id = cookies.signed[:session_token]).present?
      if (session_record = Session.find_by(id: session_id))
        Current.session = session_record
        head :forbidden unless session_record.user&.super_admin?
      else
        redirect_to new_session_url
      end
    else
      redirect_to new_session_url
    end
  end

  # You can use your own model classes if you need to extend (or even override) default
  # Doorkeeper models such as `Application`, `AccessToken` and `AccessGrant.
  #
  # By default Doorkeeper ActiveRecord ORM uses its own classes:
  #
  # access_token_class "Doorkeeper::AccessToken"
  # access_grant_class "Doorkeeper::AccessGrant"
  # application_class "Doorkeeper::Application"
  #
  # Don't forget to include Doorkeeper ORM mixins into your custom models:
  #
  #   *  ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken - for access token
  #   *  ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant - for access grant
  #   *  ::Doorkeeper::Orm::ActiveRecord::Mixins::Application - for application (OAuth2 clients)
  #
  # For example:
  #
  # access_token_class "MyAccessToken"
  #
  # class MyAccessToken < ApplicationRecord
  #   include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
  #
  #   self.table_name = "hey_i_wanna_my_name"
  #
  #   def destroy_me!
  #     destroy
  #   end
  # end

  # Enables polymorphic Resource Owner association for Access Tokens and Access Grants.
  # By default this option is disabled.
  #
  # Make sure you properly setup you database and have all the required columns (run
  # `bundle exec rails generate doorkeeper:enable_polymorphic_resource_owner` and execute Rails
  # migrations).
  #
  # If this option enabled, Doorkeeper will store not only Resource Owner primary key
  # value, but also it's type (class name). See "Polymorphic Associations" section of
  # Rails guides: https://guides.rubyonrails.org/association_basics.html#polymorphic-associations
  #
  # [NOTE] If you apply this option on already existing project don't forget to manually
  # update `resource_owner_type` column in the database and fix migration template as it will
  # set NOT NULL constraint for Access Grants table.
  #
  # use_polymorphic_resource_owner

  # If you are planning to use Doorkeeper in Rails 5 API-only application, then you might
  # want to use API mode that will skip all the views management and change the way how
  # Doorkeeper responds to a requests.
  #
  # api_only

  # Enforce token request content type to application/x-www-form-urlencoded.
  # It is not enabled by default to not break prior versions of the gem.
  #
  # enforce_content_type

  # Authorization Code expiration time (default: 10 minutes).
  #
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default: 2 hours).
  # If you set this to `nil` Doorkeeper will not expire the token and omit expires_in in response.
  # It is RECOMMENDED to set expiration time explicitly.
  # Prefer access_token_expires_in 100.years or similar,
  # which would be functionally equivalent and avoid the risk of unexpected behavior by callers.
  #
  access_token_expires_in 1.year

  # Assign custom TTL for access tokens. Will be used instead of access_token_expires_in
  # option if defined. In case the block returns `nil` value Doorkeeper fallbacks to
  # +access_token_expires_in+ configuration option value. If you really need to issue a
  # non-expiring access token (which is not recommended) then you need to return
  # Float::INFINITY from this block.
  #
  # `context` has the following properties available:
  #
  #   * `client` - the OAuth client application (see Doorkeeper::OAuth::Client)
  #   * `grant_type` - the grant type of the request (see Doorkeeper::OAuth)
  #   * `scopes` - the requested scopes (see Doorkeeper::OAuth::Scopes)
  #   * `resource_owner` - authorized resource owner instance (if present)
  #
  # custom_access_token_expires_in do |context|
  #   context.client.additional_settings.implicit_oauth_expiration
  # end

  # Use a custom class for generating the access token.
  # See https://doorkeeper.gitbook.io/guides/configuration/other-configurations#custom-access-token-generator
  #
  # access_token_generator '::Doorkeeper::JWT'

  # The controller +Doorkeeper::ApplicationController+ inherits from.
  # Defaults to +ActionController::Base+ unless +api_only+ is set, which changes the default to
  # +ActionController::API+. The return value of this option must be a stringified class name.
  # See https://doorkeeper.gitbook.io/guides/configuration/other-configurations#custom-controllers
  #
  # base_controller 'ApplicationController'

  # Reuse access token for the same resource owner within an application (disabled by default).
  #
  # This option protects your application from creating new tokens before old **valid** one becomes
  # expired so your database doesn't bloat. Keep in mind that when this option is enabled Doorkeeper
  # doesn't update existing token expiration time, it will create a new token instead if no active matching
  # token found for the application, resources owner and/or set of scopes.
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  #
  # You can not enable this option together with +hash_token_secrets+.
  #
  # reuse_access_token

  # In case you enabled `reuse_access_token` option Doorkeeper will try to find matching
  # token using `matching_token_for` Access Token API that searches for valid records
  # in batches in order not to pollute the memory with all the database records. By default
  # Doorkeeper uses batch size of 10 000 records. You can increase or decrease this value
  # depending on your needs and server capabilities.
  #
  # token_lookup_batch_size 10_000

  # Set a limit for token_reuse if using reuse_access_token option
  #
  # This option limits token_reusability to some extent.
  # If not set then access_token will be reused unless it expires.
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/1189
  #
  # This option should be a percentage(i.e. (0,100])
  #
  # token_reuse_limit 100

  # Only allow one valid access token obtained via client credentials
  # per client. If a new access token is obtained before the old one
  # expired, the old one gets revoked (disabled by default)
  #
  # When enabling this option, make sure that you do not expect multiple processes
  # using the same credentials at the same time (e.g. web servers spanning
  # multiple machines and/or processes).
  #
  # revoke_previous_client_credentials_token

  # Only allow one valid access token obtained via authorization code
  # per client. If a new access token is obtained before the old one
  # expired, the old one gets revoked (disabled by default)
  #
  # revoke_previous_authorization_code_token

  # Require non-confidential clients to use PKCE when using an authorization code
  # to obtain an access_token (disabled by default)
  #
  force_pkce

  # Hash access and refresh tokens before persisting them.
  # This will disable the possibility to use +reuse_access_token+
  # since plain values can no longer be retrieved.
  #
  # Note: If you are already a user of doorkeeper and have existing tokens
  # in your installation, they will be invalid without adding 'fallback: :plain'.
  #
  # For test environment, allow fallback to plain tokens to make testing easier
  if Rails.env.test?
    hash_token_secrets fallback: :plain
  else
    hash_token_secrets
  end
  # By default, token secrets will be hashed using the
  # +Doorkeeper::Hashing::SHA256+ strategy.
  #
  # If you wish to use another hashing implementation, you can override
  # this strategy as follows:
  #
  # hash_token_secrets using: '::Doorkeeper::Hashing::MyCustomHashImpl'
  #
  # Keep in mind that changing the hashing function will invalidate all existing
  # secrets, if there are any.

  # Hash application secrets before persisting them.
  #
  hash_application_secrets
  #
  # By default, applications will be hashed
  # with the +Doorkeeper::SecretStoring::SHA256+ strategy.
  #
  # If you wish to use bcrypt for application secret hashing, uncomment
  # this line instead:
  #
  # hash_application_secrets using: '::Doorkeeper::SecretStoring::BCrypt'

  # When the above option is enabled, and a hashed token or secret is not found,
  # you can allow to fall back to another strategy. For users upgrading
  # doorkeeper and wishing to enable hashing, you will probably want to enable
  # the fallback to plain tokens.
  #
  # This will ensure that old access tokens and secrets
  # will remain valid even if the hashing above is enabled.
  #
  # This can be done by adding 'fallback: plain', e.g. :
  #
  # hash_application_secrets using: '::Doorkeeper::SecretStoring::BCrypt', fallback: :plain

  # Issue access tokens with refresh token (disabled by default), you may also
  # pass a block which accepts `context` to customize when to give a refresh
  # token or not. Similar to +custom_access_token_expires_in+, `context` has
  # the following properties:
  #
  # `client` - the OAuth client application (see Doorkeeper::OAuth::Client)
  # `grant_type` - the grant type of the request (see Doorkeeper::OAuth)
  # `scopes` - the requested scopes (see Doorkeeper::OAuth::Scopes)
  #
  use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter confirmation: true (default: false) if you want to enforce ownership of
  # a registered application
  # NOTE: you must also run the rails g doorkeeper:application_owner generator
  # to provide the necessary support
  #
  enable_application_owner confirmation: false

  # Define access token scopes for your provider
  # For more information go to
  # https://doorkeeper.gitbook.io/guides/ruby-on-rails/scopes
  #
  default_scopes  :read
  optional_scopes :read_write

  # Allows to restrict only certain scopes for grant_type.
  # By default, all the scopes will be available for all the grant types.
  #
  # Keys to this hash should be the name of grant_type and
  # values should be the array of scopes for that grant type.
  # Note: scopes should be from configured_scopes (i.e. default or optional)
  #
  # scopes_by_grant_type password: [:write], client_credentials: [:update]

  # Forbids creating/updating applications with arbitrary scopes that are
  # not in configuration, i.e. +default_scopes+ or +optional_scopes+.
  # (disabled by default)
  #
  # enforce_configured_scopes

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out https://github.com/doorkeeper-gem/doorkeeper/wiki/Changing-how-clients-are-authenticated
  # for more information on customization
  #
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out https://github.com/doorkeeper-gem/doorkeeper/wiki/Changing-how-clients-are-authenticated
  # for more information on customization
  #
  # access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Forces the usage of the HTTPS protocol in non-native redirect uris (enabled
  # by default in non-development environments). OAuth2 delegates security in
  # communication to the HTTPS protocol so it is wise to keep this enabled.
  #
  # Callable objects such as proc, lambda, block or any object that responds to
  # #call can be used in order to allow conditional checks (to allow non-SSL
  # redirects to localhost for example).
  #
  # Allow custom URL schemes for mobile apps
  force_ssl_in_redirect_uri false

  # Specify what redirect URI's you want to block during Application creation.
  # Any redirect URI is allowed by default.
  #
  # You can use this option in order to forbid URI's with 'javascript' scheme
  # for example.
  #
  # Block javascript URIs but allow custom schemes
  forbid_redirect_uri { |uri| uri.scheme.to_s.downcase == "javascript" }

  # Allows to set blank redirect URIs for Applications in case Doorkeeper configured
  # to use URI-less OAuth grant flows like Client Credentials or Resource Owner
  # Password Credentials. The option is on by default and checks configured grant
  # types, but you **need** to manually drop `NOT NULL` constraint from `redirect_uri`
  # column for `oauth_applications` database table.
  #
  # You can completely disable this feature with:
  #
  # allow_blank_redirect_uri false
  #
  # Or you can define your custom check:
  #
  # allow_blank_redirect_uri do |grant_flows, client|
  #   client.superapp?
  # end

  # Specify how authorization errors should be handled.
  # By default, doorkeeper renders json errors when access token
  # is invalid, expired, revoked or has invalid scopes.
  #
  # If you want to render error response yourself (i.e. rescue exceptions),
  # set +handle_auth_errors+ to `:raise` and rescue Doorkeeper::Errors::InvalidToken
  # or following specific errors:
  #
  #   Doorkeeper::Errors::TokenForbidden, Doorkeeper::Errors::TokenExpired,
  #   Doorkeeper::Errors::TokenRevoked, Doorkeeper::Errors::TokenUnknown
  #
  # handle_auth_errors :raise
  #
  # If you want to redirect back to the client application in accordance with
  # https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1, you can set
  # +handle_auth_errors+ to :redirect
  #
  # handle_auth_errors :redirect

  # Customize token introspection response.
  # Allows to add your own fields to default one that are required by the OAuth spec
  # for the introspection response. It could be `sub`, `aud` and so on.
  # This configuration option can be a proc, lambda or any Ruby object responds
  # to `.call` method and result of it's invocation must be a Hash.
  #
  # custom_introspection_response do |token, context|
  #   {
  #     "sub": "Z5O3upPC88QrAjx00dis",
  #     "aud": "https://protected.example.net/resource",
  #     "username": User.find(token.resource_owner_id).username
  #   }
  # end
  #
  # or
  #
  # custom_introspection_response CustomIntrospectionResponder

  # Specify what grant flows are enabled in array of Strings. The valid
  # strings and the flows they enable are:
  #
  # "authorization_code" => Authorization Code Grant Flow
  # "implicit"           => Implicit Grant Flow
  # "password"           => Resource Owner Password Credentials Grant Flow
  # "client_credentials" => Client Credentials Grant Flow
  #
  # If not specified, Doorkeeper enables authorization_code and
  # client_credentials.
  #
  # implicit and password grant flows have risks that you should understand
  # before enabling:
  #   https://datatracker.ietf.org/doc/html/rfc6819#section-4.4.2
  #   https://datatracker.ietf.org/doc/html/rfc6819#section-4.4.3
  #
  # grant_flows %w[authorization_code client_credentials]

  # Allows to customize OAuth grant flows that +each+ application support.
  # You can configure a custom block (or use a class respond to `#call`) that must
  # return `true` in case Application instance supports requested OAuth grant flow
  # during the authorization request to the server. This configuration +doesn't+
  # set flows per application, it only allows to check if application supports
  # specific grant flow.
  #
  # For example you can add an additional database column to `oauth_applications` table,
  # say `t.array :grant_flows, default: []`, and store allowed grant flows that can
  # be used with this application there. Then when authorization requested Doorkeeper
  # will call this block to check if specific Application (passed with client_id and/or
  # client_secret) is allowed to perform the request for the specific grant type
  # (authorization, password, client_credentials, etc).
  #
  # Example of the block:
  #
  #   ->(flow, client) { client.grant_flows.include?(flow) }
  #
  # In case this option invocation result is `false`, Doorkeeper server returns
  # :unauthorized_client error and stops the request.
  #
  # @param allow_grant_flow_for_client [Proc] Block or any object respond to #call
  # @return [Boolean] `true` if allow or `false` if forbid the request
  #
  # allow_grant_flow_for_client do |grant_flow, client|
  #   # `grant_flows` is an Array column with grant
  #   # flows that application supports
  #
  #   client.grant_flows.include?(grant_flow)
  # end

  # If you need arbitrary Resource Owner-Client authorization you can enable this option
  # and implement the check your need. Config option must respond to #call and return
  # true in case resource owner authorized for the specific application or false in other
  # cases.
  #
  # By default all Resource Owners are authorized to any Client (application).
  #
  # authorize_resource_owner_for_client do |client, resource_owner|
  #   resource_owner.admin? || client.owners_allowlist.include?(resource_owner)
  # end

  # Allows additional data fields to be sent while granting access to an application,
  # and for this additional data to be included in subsequently generated access tokens.
  # The 'authorizations/new' page will need to be overridden to include this additional data
  # in the request params when granting access. The access grant and access token models
  # will both need to respond to these additional data fields, and have a database column
  # to store them in.
  #
  # Example:
  # You have a multi-tenanted platform and want to be able to grant access to a specific
  # tenant, rather than all the tenants a user has access to. You can use this config
  # option to specify that a ':tenant_id' will be passed when authorizing. This tenant_id
  # will be included in the access tokens. When a request is made with one of these access
  # tokens, you can check that the requested data belongs to the specified tenant.
  #
  # Default value is an empty Array: []
  # custom_access_token_attributes [:tenant_id]

  # Hook into the strategies' request & response life-cycle in case your
  # application needs advanced customization or logging:
  #
  # before_successful_strategy_response do |request|
  #   puts "BEFORE HOOK FIRED! #{request}"
  # end
  #
  # after_successful_strategy_response do |request, response|
  #   puts "AFTER HOOK FIRED! #{request}, #{response}"
  # end

  # Hook into Authorization flow in order to implement Single Sign Out
  # or add any other functionality. Inside the block you have an access
  # to `controller` (authorizations controller instance) and `context`
  # (Doorkeeper::OAuth::Hooks::Context instance) which provides pre auth
  # or auth objects with issued token based on hook type (before or after).
  #
  # before_successful_authorization do |controller, context|
  #   Rails.logger.info(controller.request.params.inspect)
  #
  #   Rails.logger.info(context.pre_auth.inspect)
  # end
  #
  # after_successful_authorization do |controller, context|
  #   controller.session[:logout_urls] <<
  #     Doorkeeper::Application
  #       .find_by(controller.request.params.slice(:redirect_uri))
  #       .logout_uri
  #
  #   Rails.logger.info(context.auth.inspect)
  #   Rails.logger.info(context.issued_token)
  # end

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  #
  # skip_authorization do |resource_owner, client|
  #   client.superapp? or resource_owner.admin?
  # end

  # Configure custom constraints for the Token Introspection request.
  # By default this configuration option allows to introspect a token by another
  # token of the same application, OR to introspect the token that belongs to
  # authorized client (from authenticated client) OR when token doesn't
  # belong to any client (public token). Otherwise requester has no access to the
  # introspection and it will return response as stated in the RFC.
  #
  # Block arguments:
  #
  # @param token [Doorkeeper::AccessToken]
  #   token to be introspected
  #
  # @param authorized_client [Doorkeeper::Application]
  #   authorized client (if request is authorized using Basic auth with
  #   Client Credentials for example)
  #
  # @param authorized_token [Doorkeeper::AccessToken]
  #   Bearer token used to authorize the request
  #
  # In case the block returns `nil` or `false` introspection responses with 401 status code
  # when using authorized token to introspect, or you'll get 200 with { "active": false } body
  # when using authorized client to introspect as stated in the
  # RFC 7662 section 2.2. Introspection Response.
  #
  # Using with caution:
  # Keep in mind that these three parameters pass to block can be nil as following case:
  #  `authorized_client` is nil if and only if `authorized_token` is present, and vice versa.
  #  `token` will be nil if and only if `authorized_token` is present.
  # So remember to use `&` or check if it is present before calling method on
  # them to make sure you doesn't get NoMethodError exception.
  #
  # You can define your custom check:
  #
  # allow_token_introspection do |token, authorized_client, authorized_token|
  #   if authorized_token
  #     # customize: require `introspection` scope
  #     authorized_token.application == token&.application ||
  #       authorized_token.scopes.include?("introspection")
  #   elsif token.application
  #     # `protected_resource` is a new database boolean column, for example
  #     authorized_client == token.application || authorized_client.protected_resource?
  #   else
  #     # public token (when token.application is nil, token doesn't belong to any application)
  #     true
  #   end
  # end
  #
  # Or you can completely disable any token introspection:
  #
  # allow_token_introspection false
  #
  # If you need to block the request at all, then configure your routes.rb or web-server
  # like nginx to forbid the request.

  # WWW-Authenticate Realm (default: "Doorkeeper").
  #
  # realm "Doorkeeper"
end
