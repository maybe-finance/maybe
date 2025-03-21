module Assistant::Provideable
  extend ActiveSupport::Concern

  ChatResponse = Data.define(:message, :tool_calls)

  def chat_response(messages:, model: nil, functions: [], instructions: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end
end
