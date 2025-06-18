# frozen_string_literal: true

json.id chat.id
json.title chat.title
json.error chat.error.present? ? chat.error : nil
json.created_at chat.created_at.iso8601
json.updated_at chat.updated_at.iso8601
