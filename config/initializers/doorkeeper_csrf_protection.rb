# Disable CSRF protection for Doorkeeper endpoints.
#
# OAuth requests (both the authorization endpoint hit by users and the token
# endpoint hit by confidential/public clients) are performed by third-party
# clients that do not have access to the Rails session, and therefore cannot
# include the standard CSRF token. Requiring the token in these controllers
# breaks the OAuth flow with an ActionController::InvalidAuthenticityToken
# error. It is safe to disable CSRF verification here because Doorkeeper's
# endpoints already implement their own security semantics defined by the
# OAuth 2.0 specification (PKCE, client/secret checks, etc.).
#
# This hook runs on each application reload in development and ensures the
# callback is applied after Doorkeeper loads its controllers.
Rails.application.config.to_prepare do
  # Doorkeeper::ApplicationController is the base controller for all
  # Doorkeeper-provided controllers (AuthorizationsController, TokensController,
  # TokenInfoController, etc.). Removing the authenticity-token filter here
  # cascades to all of them.
  Doorkeeper::ApplicationController.skip_forgery_protection
end
