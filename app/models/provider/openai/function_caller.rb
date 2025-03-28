class Provider::Openai::FunctionCaller
  def initialize(functions)
    @functions = functions
  end

  def openai_tools
    functions.map do |fn|
      {
        type: "function",
        name: fn.name,
        description: fn.description,
        parameters: fn.params_schema,
        strict: fn.strict_mode?
      }
    end
  end

  def build_results_input(function_calls)
    function_calls.map do |fc|
      {
        type: "function_call_output",
        call_id: fc.provider_call_id,
        output: fc.result.to_json
      }
    end
  end

  def fulfill_request(function_request)
    fn_name = function_request[:name]
    fn_args = JSON.parse(function_request[:arguments])
    fn = get_function(fn_name)
    result = fn.call(fn_args)

    Provider::LlmProvider::FunctionCall.new(
      provider_id: function_request[:id],
      provider_call_id: function_request[:call_id],
      name: fn_name,
      arguments: fn_args,
      result: result
    )
  rescue => e
    fn_execution_details = {
      fn_name: fn_name,
      fn_args: fn_args
    }

    raise Provider::Openai::Error.new(e, fn_execution_details)
  end

  private
    attr_reader :functions

    def get_function(name)
      functions.find { |f| f.name == name }
    end
end
