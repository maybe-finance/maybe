class Assistant::FunctionToolCaller
  Error = Class.new(StandardError)
  FunctionExecutionError = Class.new(Error)

  attr_reader :functions

  def initialize(functions = [])
    @functions = functions
  end

  def fulfill_requests(function_requests)
    function_requests.map do |function_request|
      result = execute(function_request)

      ToolCall::Function.from_function_request(function_request, result)
    end
  end

  def function_definitions
    functions.map(&:to_definition)
  end

  private
    def execute(function_request)
      fn = find_function(function_request)
      fn_args = JSON.parse(function_request.function_args)
      fn.call(fn_args)
    rescue => e
      raise FunctionExecutionError.new(
        "Error calling function #{fn.name} with arguments #{fn_args}: #{e.message}"
      )
    end

    def find_function(function_request)
      functions.find { |f| f.name == function_request.function_name }
    end
end
