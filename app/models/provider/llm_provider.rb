module Provider::LlmProvider
  extend ActiveSupport::Concern

  def chat_response(message, instructions: nil, available_functions: [], streamer: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end

  private
    StreamChunk = Data.define(:provider_type, :data)
    ChatResponse = Data.define(:provider_id, :model, :messages, :function_calls) do
      def final?
        function_calls.empty?
      end
    end
    Message = Data.define(:provider_id, :content)
    FunctionCall = Data.define(:provider_id, :provider_call_id, :name, :arguments, :result)
end
