module Provider::LlmConcept
  extend ActiveSupport::Concern

  ChatMessage = Data.define(:id, :output_text)
  ChatStreamChunk = Data.define(:type, :data)
  ChatResponse = Data.define(:id, :model, :messages, :function_requests)
  ChatFunctionRequest = Data.define(:id, :call_id, :function_name, :function_args)

  def chat_response(prompt, model:, instructions: nil, functions: [], function_results: [], streamer: nil, previous_response_id: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end
end
