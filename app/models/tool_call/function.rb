class ToolCall::Function < ToolCall
  validates :function_name, presence: true
end
