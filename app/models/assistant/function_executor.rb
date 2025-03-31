class Assistant::FunctionExecutor
  Error = Class.new(StandardError)

  attr_reader :functions

  def initialize(functions = [])
    @functions = functions
  end

  def execute(function_request)
    fn = find_function(function_request)
    fn_args = JSON.parse(function_request.function_args)
    fn.call(fn_args)
  rescue => e
    raise Error.new(
      "Error calling function #{fn.name} with arguments #{fn_args}: #{e.message}"
    )
  end

  private
    def find_function(function_request)
      functions.find { |f| f.name == function_request.function_name }
    end
end
