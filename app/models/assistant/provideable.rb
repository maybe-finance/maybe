# The interface all LLM providers must implement
module Assistant::Provideable
  extend ActiveSupport::Concern

  ChatResponseMessage = Data.define(:id, :content)
  ChatResponseFunctionExecution = Data.define(:id, :call_id, :name, :arguments, :result)
  ChatResponse = Data.define(:id, :messages, :functions, :model)

  def chat_response(message, instructions: nil, available_functions: [], streamer: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end

  def supports_model?(model)
    raise NotImplementedError, "Subclasses must implement #supports_model?"
  end
end
