class Assistant
  include Provided, ToolCallable

  UnknownModelError = Class.new(StandardError)

  class << self
    def for_chat(chat)
      new(chat)
    end
  end

  def initialize(chat)
    @chat = chat
  end

  def respond_to(message)
    model = get_model(message.ai_model)

    raise UnknownModelError, "Unknown model: #{message.ai_model}" unless model.present?

    response = model.provider.chat({
      model: model.name,
      messages: [
        {
          role: "user",
          content: message.content
        }
      ]
    })

    # test_tool_call = {
    #   type: "function",
    #   function_name: "get_balance_sheet",
    #   function_params: { test: "param" }
    # }

    # fn = available_functions[test_tool_call[:function_name]]

    # raise "Function not found: #{test_tool_call[:function_name]}" unless fn.present?

    # result = fn.executor.call(test_tool_call[:function_params])

    # tool_call = ToolCall::Function.new(
    #   function_name: test_tool_call[:function_name],
    #   result: result
    # )

    # tool_call.save!

    # tool_call.chat_message
  end
end
