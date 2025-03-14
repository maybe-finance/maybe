module Promptable
  extend ActiveSupport::Concern

  # The openai ruby gem hasn't yet added support for the responses endpoint.
  # TODO: Remove this once the gem implements it.
  class CustomOpenAI < OpenAI::Client
    def responses(parameters: {})
      json_post(path: "/responses", parameters: parameters)
    end
  end

  class_methods do
    def openai_client
      api_key = ENV.fetch("OPENAI_ACCESS_TOKEN", Setting.openai_access_token)

      return nil unless api_key.present?

      CustomOpenAI.new(access_token: api_key)
    end
  end

  # Convert model data to a format that's readable by AI
  def to_ai_readable_hash
    raise NotImplementedError, "#{self.class} must implement to_ai_readable_hash"
  end

  # Provide detailed financial summary for AI queries
  def detailed_summary
    raise NotImplementedError, "#{self.class} must implement detailed_summary"
  end

  # Generate financial insights and analysis
  def financial_insights
    raise NotImplementedError, "#{self.class} must implement financial_insights"
  end

  # Format all data for AI in a structured way
  def to_ai_response(include_insights: true)
    response = {
      data: to_ai_readable_hash,
      details: detailed_summary
    }

    response[:insights] = financial_insights if include_insights
    response
  end

  private

    def openai_client
      self.class.openai_client
    end

    # Format currency values consistently for AI display
    def format_currency(amount, currency = family.currency)
      Money.new(amount, currency).format
    end

    # Format percentage values consistently for AI display
    def format_percentage(value)
      return "0.00%" if value.nil? || value.zero?
      "#{value.round(2)}%"
    end

    # Format date values consistently for AI display
    def format_date(date)
      date.strftime("%B %d, %Y")
    end
end
