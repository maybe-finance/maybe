class ToolCall < ApplicationRecord
  belongs_to :message

  def to_h
    {
      provider_id: provider_id,
      provider_call_id: provider_call_id,
      name: function_name,
      arguments: function_arguments,
      result: function_result
    }
  end
end
