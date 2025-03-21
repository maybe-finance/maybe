module Assistant::Provideable
  extend ActiveSupport::Concern

  ChatResponse = Data.define(:messages)

  def fetch_chat_response(params = {})
    raise NotImplementedError, "Subclasses must implement #chat"
  end

  def tools_config(assistant_functions = [])
    raise NotImplementedError, "Subclasses must implement #tools_config"
  end
end
