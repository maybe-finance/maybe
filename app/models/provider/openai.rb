class Provider::Openai < Provider
  include LlmProvider

  MODELS = %w[gpt-4o]

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def supports_model?(model)
    MODELS.include?(model)
  end

  def chat_response(prompt, model:, instructions: nil, functions: [], function_results: [], previous_response_id: nil)
    with_provider_response do
      proxy_streamer = proc do |chunk|
        type = chunk.dig("type")
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

      client.responses.create(parameters: {
        model: model,
        input: prompt_input + function_results_input,
        instructions: instructions,
        tools: tools,
        previous_response_id: previous_response_id,
        stream: streamer
      })
    end
  end

  private
    attr_reader :client
end
