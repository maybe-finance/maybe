# A stream proxy for OpenAI chat responses
#
# - Consumes OpenAI stream chunks
# - Outputs generic stream chunks to a "subscriber" (e.g. `Assistant`) if subscriber is supplied
class Provider::Openai::ChatStreamer
  include Provider::Openai::Parser

  def initialize(output_stream)
    @output_stream = output_stream
  end

  def call(chunk)
    output = parse_chunk(chunk)
    output_stream.call(output) unless output.nil?
  end

  private
    attr_reader :output_stream

    Chunk = Provider::LlmProvider::StreamChunk
    Response = Provider::LlmProvider::ChatResponse
    Message = Provider::LlmProvider::Message

    def parse_chunk(chunk)
      type = chunk.dig("type")

      case type
      when "response.output_text.delta", "response.refusal.delta"
        build_chunk("output_text", chunk.dig("delta"))
      when "response.function_call_arguments.done"
        build_chunk("function_request", chunk.dig("arguments"))
      when "response.completed"
        handle_response(chunk.dig("response"))
      end
    end

    def handle_response(response)
      function_requests = extract_function_requests(response)

      function_calls = function_requests.map do |function_request|
        @function_caller.fulfill_request(function_request)
      end

      normalized_response = build_response(response, function_calls: function_calls)

      build_chunk("response", normalized_response)
    end

    def build_chunk(type, data)
      Chunk.new(
        provider_type: type,
        data: data
      )
    end

    def build_response(response, function_calls: [])
      Response.new(
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
      client.responses.create(parameters: {
        model: model,
        input: input,
        instructions: instructions,
        tools: function_caller.openai_tools,
        previous_response_id: previous_response_id,
        stream: streamer
      })
    end
end
