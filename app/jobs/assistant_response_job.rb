class AssistantResponseJob < ApplicationJob
  queue_as :default

  def perform(chat)
    chat.ask_assistant
  end
end
