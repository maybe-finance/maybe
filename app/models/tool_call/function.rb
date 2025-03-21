class ToolCall::Function < ToolCall
  validates :function_name, :function_arguments, :function_result, presence: true
end
