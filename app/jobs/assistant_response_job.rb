class AssistantResponseJob < ApplicationJob
  queue_as :high_priority

  def perform(message)
    message.request_response
  end
end
