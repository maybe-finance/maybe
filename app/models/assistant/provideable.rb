# The interface all LLM providers must implement
module Assistant::Provideable
  extend ActiveSupport::Concern

  ChatResponseMessage = Data.define(:role, :content)
  ChatResponseToolCall = Data.define(:function, :arguments)
  ChatResponse = Data.define(:message, :tool_calls)

  def chat_response(messages:, model: nil, functions: [], instructions: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end
end
