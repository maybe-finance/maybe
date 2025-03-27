module Provider::Concept::LLM
  extend ActiveSupport::Concern

  def chat_response(message, instructions: nil, available_functions: [], streamer: nil)
    raise NotImplementedError, "Subclasses must implement #chat_response"
  end
end
