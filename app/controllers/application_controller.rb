class ApplicationController < ActionController::Base
  include AutoSync, Authentication, Invitable, SelfHostable, StoreLocation
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

    def with_sidebar
      return "turbo_rails/frame" if turbo_frame_request?

      "with_sidebar"
    end
end
