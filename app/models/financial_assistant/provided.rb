module FinancialAssistant::Provided
  extend ActiveSupport::Concern

  # Placeholder for AI chat PR
  def llm_provider_for(model_key)
    case model_key
    when "gpt-4o"
      Providers.openai
    else
      raise "Unknown LLM model key: #{model_key}"
    end
  end
end
