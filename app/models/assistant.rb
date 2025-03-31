class Assistant
  include Provided, Configurable

  attr_reader :chat, :instructions

  class << self
    def for_chat(chat)
      config = config_for(chat)
      new(chat, instructions: config[:instructions], functions: config[:functions])
    end
  end

  def initialize(chat, instructions: nil, functions: [])
    @chat = chat
    @instructions = instructions
    @functions = functions
  end

  def respond_to(message)
    pause_to_think

    streamer = Assistant::ResponseStreamer.new(
      prompt: message.content,
      model: message.ai_model,
      assistant: self,
    )

    streamer.stream_response
  rescue => e
    chat.add_error(e)
  end

  def fulfill_function_requests(function_requests)
    function_requests.map do |fn_request|
      result = function_executor.execute(fn_request)

      ToolCall::Function.new(
        provider_id: fn_request.id,
        provider_call_id: fn_request.call_id,
        function_name: fn_request.function_name,
        function_arguments: fn_request.function_arguments,
        function_result: result
      )
    end
  end

  def callable_functions
    functions.map do |fn|
      fn.new(chat.user)
    end
  end

  def update_thinking(thought)
    chat.broadcast_update target: "thinking-indicator", partial: "chats/thinking_indicator", locals: { chat: chat, message: thought }
  end

  def stop_thinking
    chat.broadcast_remove target: "thinking-indicator"
  end

  private
    attr_reader :functions

    def function_executor
      @function_executor ||= FunctionExecutor.new(callable_functions)
    end

    def pause_to_think
      sleep 1
    end
end
