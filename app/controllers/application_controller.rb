class ApplicationController < ActionController::Base
  include Authentication, Invitable, SelfHostable
  include Pagy::Backend

  default_form_builder ApplicationFormBuilder

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
