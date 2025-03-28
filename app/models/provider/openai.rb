class Provider::Openai < Provider
  include LlmProvider, Parser

  # Subclass so errors caught in this provider are raised as Provider::Openai::Error
  Error = Class.new(Provider::Error)

  MODELS = %w[gpt-4o]

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def supports_model?(model)
    MODELS.include?(model)
  end

  def chat_response(prompt, model:, instructions: nil, functions: [], function_results: [], streamer: nil, previous_response_id: nil)
    with_provider_response do
      proxy_streamer = proc do |chunk|
        type = chunk.dig("type")

        case type
        when "response.output_text.delta", "response.refusal.delta"
          streamer.call(StreamChunk.new(type: "output_text", data: chunk.dig("delta")))
        when "response.completed"
          raw_response = chunk.dig("response")

          messages = extract_messages(raw_response).map do |message|
            Message.new(
              id: message[:id],
              output_text: message[:output_text]
            )
          end

          function_requests = extract_function_requests(raw_response).map do |function_request|
            FunctionRequest.new(
              id: function_request[:id],
              call_id: function_request[:call_id],
              function_name: function_request[:name],
              function_args: function_request[:arguments]
            )
          end

          response = ChatResponse.new(
            id: extract_id(raw_response),
            model: extract_model(raw_response),
            messages: messages,
            function_requests: function_requests
          )

          streamer.call(StreamChunk.new(type: "response", data: response))
        end
      end

      function_results_input = function_results.map do |fn_result|
        {
          type: "function_call_output",
          call_id: fn_result[:provider_call_id],
          output: fn_result[:result].to_json
        }
      end

      prompt_input = [ { role: "user", content: prompt } ]

      tools = functions.map do |fn|
        {
          type: "function",
          name: fn[:name],
          description: fn[:description],
          parameters: fn[:params_schema],
          strict: fn[:strict]
        }
      end

      raw_response = client.responses.create(parameters: {
        model: model,
        input: prompt_input + function_results_input,
        instructions: instructions,
        tools: tools,
        previous_response_id: previous_response_id,
        stream: streamer.present? ? proxy_streamer : nil
      })

      messages = extract_messages(raw_response).map do |message|
        Message.new(
          id: message[:id],
          output_text: message[:output_text]
        )
      end

      function_requests = extract_function_requests(raw_response).map do |function_request|
        FunctionRequest.new(
          id: function_request[:id],
          call_id: function_request[:call_id],
          function_name: function_request[:name],
          function_args: function_request[:arguments]
        )
      end

      ChatResponse.new(
        id: extract_id(raw_response),
        model: extract_model(raw_response),
        messages: messages,
        function_requests: function_requests
      )
    end
  end

  private
    attr_reader :client
end
