class ToolCall::Function < ToolCall
  validates :function_name, :function_result, presence: true
  validates :function_arguments, presence: true, allow_blank: true
end
