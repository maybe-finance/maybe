class AssistantMessage < Message
  validates :ai_model, presence: true

  def role
    "assistant"
  end

  def broadcast?
    true
  end
end
