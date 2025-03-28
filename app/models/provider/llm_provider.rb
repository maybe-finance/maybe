module Provider::LlmProvider
  extend ActiveSupport::Concern

  def chat_response(prompt, model:, instructions: nil, functions: [], function_results: [], streamer: nil, previous_response_id: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end

  private
    Message = Data.define(:id, :output_text)
    StreamChunk = Data.define(:type, :data)
    ChatResponse = Data.define(:id, :model, :messages, :function_requests)
    FunctionRequest = Data.define(:id, :call_id, :function_name, :function_args)
end
