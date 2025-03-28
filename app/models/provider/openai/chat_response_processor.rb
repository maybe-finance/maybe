class Provider::Openai::ChatResponseProcessor
  include Provider::Openai::Parser

  def initialize(message:, function_caller:, client:, subscribers:, instructions: nil)
    @client = client
    @message = message
    @instructions = instructions
    @function_caller = function_caller
    @streamer = build_streamer(subscribers)
  end

  def build_streamer(subscribers)
    ChatStreamer.new(
      client: client,
      function_caller: function_caller,
      subscribers: subscribers
    )
  end

  def process
    raw_first_response = fetch_response(input, previous_response_id: previous_openai_response_id)

    function_requests = extract_function_requests(raw_first_response)

    function_calls = function_requests.map do |function_request|
      function_caller.fulfill_request(function_request)
    end

    first_response = build_response(raw_first_response, function_calls: function_calls)

    if first_response.function_calls.empty?
      return [ first_response ]
    end

    raw_follow_up_response = fetch_response(
      input + function_caller.build_results_input(function_calls),
      previous_response_id: first_response.provider_id,
    )

    follow_up_response = build_response(raw_follow_up_response)

    [ first_response, follow_up_response ]
  end

  private
    attr_reader :client, :message, :instructions, :streamer, :function_caller

    StreamChunk = Provider::LlmProvider::StreamChunk
    ChatResponse = Provider::LlmProvider::ChatResponse
    Message = Provider::LlmProvider::Message
    FunctionCall = Provider::LlmProvider::FunctionCall
    Error = Provider::Openai::Error

    def build_response(response, function_calls: [])
      ChatResponse.new(
        provider_id: extract_id(response),
        model: extract_model(response),
        messages: extract_messages(response).map do |msg|
          Message.new(
            provider_id: msg[:id],
            content: msg[:output_text]
          )
        end,
        function_calls: function_calls
      )
    end

    def fetch_response(input, previous_response_id: nil)
      # raw_response = nil

      # internal_streamer = proc do |chunk|
      #   type = chunk.dig("type")

      #   if type == "response.completed"
      #     raw_response = chunk.dig("response")
      #   end

      #   if streamer.present?
      #     case type
      #     when "response.output_text.delta", "response.refusal.delta"
      #       # We don't distinguish between text and refusal yet, so stream both the same
      #       streamer.call(StreamChunk.new(provider_type: "output_text", data: chunk.dig("delta")))
      #     when "response.function_call_arguments.done"
      #       streamer.call(StreamChunk.new(provider_type: "function_request", data: chunk.dig("arguments")))
      #     when "response.completed"
      #       normalized = normalize_chat_response(chunk.dig("response"), function_results: function_results)
      #       streamer.call(StreamChunk.new(provider_type: "response", data: normalized))
      #     end
      #   end
      # end
      client.responses.create(parameters: {
        model: model,
        input: input,
        instructions: instructions,
        tools: function_caller.openai_tools,
        previous_response_id: previous_response_id,
        stream: streamer
      })
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
end
