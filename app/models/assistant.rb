class Assistant
  include Provided, Configurable, Broadcastable

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
    assistant_message = AssistantMessage.new(
      chat: chat,
      content: "",
      ai_model: message.ai_model
    )

    responder = Assistant::Responder.new(
      message: message,
      instructions: instructions,
      function_tool_caller: function_tool_caller,
      llm: get_model_provider(message.ai_model)
    )

    responder.on(:output_text) do |text|
      stop_thinking
      assistant_message.append_text!(text)
    end

    responder.on(:response) do |data|
      update_thinking("Analyzing your data...")

      Chat.transaction do
        if data[:function_tool_calls].present?
          assistant_message.append_tool_calls!(data[:function_tool_calls])
        end

        chat.update_latest_response!(data[:id])
      end
    end

    responder.respond(previous_response_id: chat.latest_assistant_response_id)
  rescue => e
    stop_thinking
    chat.add_error(e)
  end

  private
    attr_reader :functions

    def function_tool_caller
      function_instances = functions.map do |fn|
        fn.new(chat.user)
      end

      @function_tool_caller ||= FunctionToolCaller.new(function_instances)
    end
end
