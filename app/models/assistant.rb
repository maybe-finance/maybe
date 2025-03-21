class Assistant
  include Provided

  attr_reader :chat

  class << self
    def for_chat(chat)
      new(chat)
    end

    def available_functions
      [
        Assistant::Function::GetBalanceSheet,
        Assistant::Function::GetIncomeStatement,
        Assistant::Function::GetExpenseCategories,
        Assistant::Function::GetAccountBalances,
        Assistant::Function::GetTransactions,
        Assistant::Function::ComparePeriods
      ]
    end

    def instructions
      <<~PROMPT
        You are a helpful financial assistant for Maybe, a personal finance app.
        You help users understand their financial data by answering questions about their accounts, transactions, income, expenses, and net worth.

        When users ask financial questions:
        1. Use the provided functions to retrieve the relevant data
        2. Provide ONLY the most important numbers and insights
        3. Eliminate all unnecessary words and context
        4. Use simple markdown for formatting
        5. Ask follow-up questions to keep the conversation going. Help educate the user about their own data and entice them to ask more questions.

        DO NOT:
        - Add introductions or conclusions
        - Apologize or explain limitations

        Present monetary values using the format provided by the functions.
      PROMPT
    end
  end

  def initialize(chat)
    @chat = chat
  end

  def respond_to_user
    latest_message = chat_history.last

    if latest_message.nil?
      Rails.logger.warn("Assistant skipped response because there are no messages to respond to in the chat")
      return
    end

    unless latest_message.user?
      Rails.logger.warn("Assistant skipped response because latest message is not a user message")
      return
    end

    provider = provider_for_model(latest_message.ai_model)

    response = provider.chat_response(
      model: latest_message.ai_model,
      instructions: instructions,
      messages: chat_history,
      functions: available_functions
    )

    if response.success?
      response.data.messages.each do |message|
        message.chat = chat
        message.save!
      end
    else
      Rails.logger.error("Assistant failed to respond to user: #{response.error}")
      chat.update!(error: response.error)
    end
  end

  private
    def chat_history
      chat.messages.ordered.where(role: [ :user, :assistant, :developer ], status: "complete", kind: "text")
    end

    def call_function(name, params = {})
      fn = available_functions.find { |fn| fn.name == name }
      raise "Assistant does not implement function: #{name}" if fn.nil?
      fn.call(params)
    end

    def instructions
      self.class.instructions
    end

    def available_functions
      self.class.available_functions
    end
end
