class FinancialAssistant
  include Provided

  def initialize(chat)
    @chat = chat
  end

  def query(prompt, model_key: "gpt-4o")
    llm_provider = self.class.llm_provider_for(model_key)
  end
end
