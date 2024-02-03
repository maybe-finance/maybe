module AuthMessagesHelper
  def auth_messages(form = nil)
    render "shared/auth_messages", flash: flash,
      errors: form&.object&.errors&.full_messages || []
  end
end
