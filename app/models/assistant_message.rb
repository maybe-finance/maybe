class AssistantMessage < Message
  validates :ai_model, presence: true

  def role
    "assistant"
  end

  def append_text!(text)
    self.content += text
    save!
  end

  def append_tool_calls!(tool_calls)
    self.tool_calls.concat(tool_calls)
    save!
  end
end
