module Chat::Debuggable
  extend ActiveSupport::Concern

  def debug_mode?
    ENV["AI_DEBUG_MODE"] == "true"
  end
end
