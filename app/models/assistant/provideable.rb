# The interface all LLM providers must implement
module Assistant::Provideable
  extend ActiveSupport::Concern

  ChatResponseMessage = Data.define(:id, :content)
  ChatResponseFunction = Data.define(:id, :call_id, :name, :arguments, :result)
  ChatResponse = Data.define(:messages, :functions)

  def chat_response(messages:, model: nil, functions: [], instructions: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end

  def supports_model?(model)
    raise NotImplementedError, "Subclasses must implement #supports_model?"
  end
end
