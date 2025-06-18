# Ensure Doorkeeper controllers use the correct layout
Rails.application.config.to_prepare do
  Doorkeeper::AuthorizationsController.layout "doorkeeper/application"
  Doorkeeper::AuthorizedApplicationsController.layout "doorkeeper/application"
  Doorkeeper::ApplicationsController.layout "doorkeeper/application"
end
