class Provider::Openai::ChatResponse
  def initialize(client:, model:, chat_history:, instructions: nil, available_functions: [])
    @client = client
    @model = model
    @instructions = instructions
    @available_functions = available_functions
    @input = build_initial_input(chat_history)
  end

  def build
    response = client.responses.create(parameters: {
      model: model,
      input: input,
      instructions: instructions,
      tools: available_tools
    })

    output = response.dig("output")
    response_model = response.dig("model")
    messages = extract_messages(output)
    pending_function_calls = extract_pending_function_calls(output)

    if pending_function_calls.empty?
      return Response.new(
        messages: messages,
        functions: [],
        model: response_model
      )
    end

    executed_function_calls = []

    pending_function_calls.each do |fc|
      result = execute_function(fc.name, fc.arguments)

      executed_function_calls << ResponseFunction.new(
        **fc.to_h,
        result: result
      )

      input << {
        type: "function_call",
        id: fc.id,
        call_id: fc.call_id,
        name: fc.name,
        arguments: fc.arguments
      }

      input << {
        type: "function_call_output",
        call_id: fc.call_id,
        output: result
      }
    end

    follow_up_response = client.responses.create(parameters: {
      model: model,
      instructions: instructions,
      input: input
    })

    messages = extract_messages(follow_up_response.dig("output"))

    Response.new(
      messages: messages,
      functions: executed_function_calls,
      model: response_model
    )
  end

  private
    attr_reader :client, :model, :instructions, :available_functions, :input

    # Expected response interface for an "LLM Provider"
    Response = Assistant::Provideable::ChatResponse
    ResponseMessage = Assistant::Provideable::ChatResponseMessage
    ResponseFunction = Assistant::Provideable::ChatResponseFunction

    def build_initial_input(chat_history)
      chat_history.map do |item|
        { role: item.role, content: item.content }
      end
    end

    def extract_messages(output)
      message_items = output.filter { |item| item.dig("type") == "message" }

      message_items.map do |item|
        output_text = item.dig("content").map do |content|
          text = content.dig("text")
          refusal = content.dig("refusal")

          text || refusal
        end.flatten.join("\n")

        ResponseMessage.new(
          id: item.dig("id"),
          content: output_text,
        )
      end
    end

    def extract_pending_function_calls(output)
      output.filter { |item| item.dig("type") == "function_call" }.map do |item|
        ResponseFunction.new(
          id: item.dig("id"),
          call_id: item.dig("call_id"),
          name: item.dig("name"),
          arguments: item.dig("arguments"),
          result: nil
        )
      end
    end

    def execute_function(name, args)
      fn = available_functions.find { |af| af.name == name }
      fn.call(args)
    end

    def available_tools
      available_functions.map do |fn|
        {
          type: "function",
          name: fn.name,
          description: fn.description,
          parameters: fn.parameters,
          strict: true
        }
      end
    end
end
