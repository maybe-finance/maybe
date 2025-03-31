class Provider::Openai::ChatConfig
  def initialize(functions: [], function_results: [])
    @functions = functions
    @function_results = function_results
  end

  def tools
    functions.map do |fn|
      {
        type: "function",
        name: fn[:name],
        description: fn[:description],
        parameters: fn[:params_schema],
        strict: fn[:strict]
      }
    end
  end

  def build_input(prompt)
    results = function_results.map do |fn_result|
      {
        type: "function_call_output",
        call_id: fn_result[:call_id],
        output: fn_result[:output].to_json
      }
    end

    [
      { role: "user", content: prompt },
      *results
    ]
  end

  private
    attr_reader :functions, :function_results
end
