class NameChatJob < ApplicationJob
  queue_as :default

  def perform(chat_id)
    chat = Chat.find(chat_id)
    nil if chat.nil? || chat.messages.empty?

    openai_client = OpenAI::Client.new

    chat_history = chat.messages.where.not(content: [ nil, "" ]).where.not(content: "...").where.not(role: "log").order(:created_at)

    messages = chat_history.map do |message|
      { role: message.role, content: message.content }
    end

    response = openai_client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "You are a highly intelligent certified financial advisor tasked with summarizing and naming a chat with the user." },
          { role: "assistant", content: <<-ASSISTANT.strip_heredoc }
            Here's the chat history:
            #{messages}

            Respond in JSON format:
            {
              "name": string, // A 3-5 word name for the chat
              "summary": string, // A 1-3 sentence summary of the chat
            }
          ASSISTANT
        ],
        temperature: 0,
        max_tokens: 500,
        response_format: { type: "json_object" }
      }
    )

    raw_response = response.dig("choices", 0, "message", "content")

    parsed_response = JSON.parse(raw_response)

    chat.update(title: parsed_response["name"], summary: parsed_response["summary"])
  end
end
