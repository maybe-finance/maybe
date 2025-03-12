class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(message)
    message.chat.generate_next_ai_response
  end
end
