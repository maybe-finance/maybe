class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  default_form_builder ApplicationFormBuilder

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def hosted_app?
    ENV["HOSTED"] == "true"
  end
  helper_method :hosted_app?
end
