module Assistant::Provideable
  extend ActiveSupport::Concern

  ChatResponse = Data.define(:messages)

  def supports_model?(model)
    raise NotImplementedError, "Subclasses must implement #supports_model?"
  end

  def chat_response(messages:, model: nil, functions: [], instructions: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end
end
