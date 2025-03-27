class Provider::Openai::ChatResponseProcessor
  def initialize(message:, client:, instructions: nil, available_functions: [], streamer: nil)
    @client = client
    @message = message
    @instructions = instructions
    @available_functions = available_functions
    @streamer = streamer
  end

  def process
    first_response = fetch_response(previous_response_id: previous_openai_response_id)

    if first_response.functions.empty?
      if streamer.present?
        streamer.call(StreamChunk.new(type: "response", data: first_response))
      end

      return first_response
    end

    executed_functions = execute_pending_functions(first_response.functions)

    follow_up_response = fetch_response(
      executed_functions: executed_functions,
      previous_response_id: first_response.id
    )

    if streamer.present?
      streamer.call(StreamChunk.new(type: "response", data: follow_up_response))
    end

    follow_up_response
  end

  private
    attr_reader :client, :message, :instructions, :available_functions, :streamer

    StreamChunk = Data.define(:type, :data)
    PendingFunction = Data.define(:id, :call_id, :name, :arguments)

    # Expected response interface for an "LLM Provider"
    Response = Assistant::Provideable::ChatResponse
    ResponseMessage = Assistant::Provideable::ChatResponseMessage
    ExecutedFunction = Assistant::Provideable::ChatResponseFunctionExecution

    def fetch_response(executed_functions: [], previous_response_id: nil)
      function_results = executed_functions.map do |executed_function|
        {
          type: "function_call_output",
          call_id: executed_function.call_id,
          output: executed_function.result.to_json
        }
      end

      prepared_input = input + function_results

      # No need to pass tools for follow-up messages that provide function results
      prepared_tools = executed_functions.empty? ? tools : []

      raw_response = nil

      internal_streamer = proc do |chunk|
        type = chunk.dig("type")

        if streamer.present?
          case type
          when "response.output_text.delta", "response.refusal.delta"
            # We don't distinguish between text and refusal yet, so stream both the same
            streamer.call(StreamChunk.new(type: "output_text", data: chunk.dig("delta")))
          when "response.function_call_arguments.done"
            streamer.call(StreamChunk.new(type: "function_request", data: chunk.dig("arguments")))
          end
        end

        if type == "response.completed"
          raw_response = chunk.dig("response")
        end
      end

      client.responses.create(parameters: {
        model: model,
        input: prepared_input,
        instructions: instructions,
        tools: prepared_tools,
        previous_response_id: previous_response_id,
        stream: internal_streamer
      })

      if raw_response.dig("status") == "failed" || raw_response.dig("status") == "incomplete"
        raise Provider::Openai::Error.new("OpenAI returned a failed or incomplete response", { chunk: chunk })
      end

      response_output = raw_response.dig("output")

      functions_output = if executed_functions.any?
        executed_functions
      else
        extract_pending_functions(response_output)
      end

      Response.new(
        id: raw_response.dig("id"),
        messages: extract_messages(response_output),
        functions: functions_output,
        model: raw_response.dig("model")
      )
    end

    def chat
      message.chat
    end

    def model
      message.ai_model
    end

    def previous_openai_response_id
      chat.latest_assistant_response_id
    end

    # Since we're using OpenAI's conversation state management, all we need to pass
    # to input is the user message we're currently responding to.
    def input
      [ { role: "user", content: message.content } ]
    end

    def extract_messages(response_output)
      message_items = response_output.filter { |item| item.dig("type") == "message" }

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

    def extract_pending_functions(response_output)
      response_output.filter { |item| item.dig("type") == "function_call" }.map do |item|
        PendingFunction.new(
          id: item.dig("id"),
          call_id: item.dig("call_id"),
          name: item.dig("name"),
          arguments: item.dig("arguments"),
        )
      end
    end

    def execute_pending_functions(pending_functions)
      pending_functions.map do |pending_function|
        execute_function(pending_function)
      end
    end

    def execute_function(fn)
      fn_instance = available_functions.find { |f| f.name == fn.name }
      parsed_args = JSON.parse(fn.arguments)
      result = fn_instance.call(parsed_args)

      ExecutedFunction.new(
        id: fn.id,
        call_id: fn.call_id,
        name: fn.name,
        arguments: parsed_args,
        result: result
      )
    rescue => e
      fn_execution_details = {
        fn_name: fn.name,
        fn_args: parsed_args
      }

      raise Provider::Openai::Error.new(e, fn_execution_details)
    end

    def tools
      available_functions.map do |fn|
        {
          type: "function",
          name: fn.name,
          description: fn.description,
          parameters: fn.params_schema,
          strict: fn.strict_mode?
        }
      end
    end
end
