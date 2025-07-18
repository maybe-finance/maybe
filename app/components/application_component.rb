class ApplicationComponent < ViewComponent::Base
  # These don't work as expected with helpers.turbo_frame_tag, etc., so we include them here
  include Turbo::FramesHelper, Turbo::StreamsHelper
end
