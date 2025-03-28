module Provider::LlmProvider
  extend ActiveSupport::Concern

  def chat_response(message, instructions: nil, available_functions: [], streamer: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end

  private
    StreamChunk = Data.define(:type, :data)
    ChatResponse = Data.define(:id, :messages, :functions, :model)
    Message = Data.define(:id, :content)
    FunctionExecution = Data.define(:id, :call_id, :name, :arguments, :result)
end
