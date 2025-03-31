class Assistant::ResponseStreamer
  MAX_LLM_CALLS = 5

  MaxCallsError = Class.new(StandardError)

  def initialize(prompt:, model:, assistant:, assistant_message: nil, llm_call_count: 0)
    @prompt = prompt
    @model = model
    @assistant = assistant
    @llm_call_count = llm_call_count
    @assistant_message = assistant_message
  end

  def call(chunk)
    case chunk.type
    when "output_text"
      assistant.stop_thinking
      assistant_message.content += chunk.data
      assistant_message.save!
    when "response"
      response = chunk.data

      assistant.chat.update!(latest_assistant_response_id: assistant_message.id)

      if response.function_requests.any?
        assistant.update_thinking("Analyzing your data...")

        function_tool_calls = assistant.fulfill_function_requests(response.function_requests)
        assistant_message.tool_calls = function_tool_calls
        assistant_message.save!

        # Circuit breaker
        raise MaxCallsError if llm_call_count >= MAX_LLM_CALLS

        follow_up_streamer = self.class.new(
          prompt: prompt,
          model: model,
          assistant: assistant,
          assistant_message: assistant_message,
          llm_call_count: llm_call_count + 1
        )

        follow_up_streamer.stream_response(
          function_results: function_tool_calls.map(&:to_h)
        )
      else
        assistant.stop_thinking
      end
    end
  end

  def stream_response(function_results: [])
    llm.chat_response(
      prompt: prompt,
      model: model,
      instructions: assistant.instructions,
      functions: assistant.callable_functions,
      function_results: function_results,
      streamer: self
    )
  end

  private
    attr_reader :prompt, :model, :assistant, :assistant_message, :llm_call_count

    def assistant_message
      @assistant_message ||= build_assistant_message
    end

    def llm
      assistant.get_model_provider(model)
    end

    def build_assistant_message
      AssistantMessage.new(
        chat: assistant.chat,
        content: "",
        ai_model: model
      )
    end
end
