class AssistantResponseJob < ApplicationJob
  queue_as :default

  def perform(message)
    message.request_response
  end
end
