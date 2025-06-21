# frozen_string_literal: true

json.id @message.id
json.chat_id @message.chat_id
json.type @message.type.underscore
json.role @message.role
json.content @message.content
json.model @message.ai_model if @message.type == "AssistantMessage"
json.created_at @message.created_at.iso8601
json.updated_at @message.updated_at.iso8601

# Note: AI response will be processed asynchronously
if @message.type == "UserMessage"
  json.ai_response_status "pending"
  json.ai_response_message "AI response is being generated"
end
