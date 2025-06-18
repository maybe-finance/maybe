# frozen_string_literal: true

json.chats @chats do |chat|
  json.id chat.id
  json.title chat.title
  json.last_message_at chat.messages.ordered.first&.created_at&.iso8601
  json.message_count chat.messages.count
  json.error chat.error.present? ? chat.error : nil
  json.created_at chat.created_at.iso8601
  json.updated_at chat.updated_at.iso8601
end

json.pagination do
  json.page @pagy.page
  json.per_page @pagy.vars[:items]
  json.total_count @pagy.count
  json.total_pages @pagy.pages
end
