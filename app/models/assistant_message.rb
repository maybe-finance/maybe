class AssistantMessage < Message
  validates :ai_model, presence: true

  def role
    "assistant"
  end

  def append_text!(text)
    self.content += text
    save!
  end
end
