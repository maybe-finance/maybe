class Assistant
  include Provided

  AssistantError = Class.new(StandardError)

  attr_reader :chat

  class << self
    def for_chat(chat)
      new(chat)
    end

    def available_functions
      [
        Assistant::Functions::GetBalanceSheet.new,
        Assistant::Functions::GetIncomeStatement.new,
        Assistant::Functions::GetExpenseCategories.new,
        Assistant::Functions::GetAccountBalances.new,
        Assistant::Functions::GetTransactions.new,
        Assistant::Functions::ComparePeriods.new
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

  def respond
    ensure_respondable!

    response = provider.chat_response(
      model: chat_model,
      instructions: chat_instructions,
      chat_history: chat_history,
      functions: chat_functions
    )

    if response.success?
      process_response_artifacts(response.data)
    else
      chat.update!(error: response.error)
      raise AssistantError, "Assistant failed to respond to user: #{response.error}"
    end
  end

  private
    def provider
      provider_for_model(chat_model)
    end

    def process_response_artifacts(data)
      messages = data.messages.map do |message|
        Message.new(
          chat: chat,
          role: "assistant",
          kind: "text",
          status: "complete",
          content: message.content,
          provider_id: message.id,
          ai_model: chat_model,
          tool_calls: data.functions.map do |fn|
            ToolCall::Function.new(
              provider_id: fn.id,
              provider_call_id: fn.call_id,
              function_name: fn.name,
              function_arguments: fn.arguments,
              function_result: fn.result
            )
          end
        )
      end

      messages.each(&:save!)
    end

    def chat_history
      chat.messages.ordered.where(role: [ :user, :assistant, :developer ], status: "complete", kind: "text")
    end

    def chat_model
      chat_history.last.ai_model
    end

    def chat_instructions
      self.class.instructions
    end

    def chat_functions
      self.class.available_functions
    end

    def ensure_respondable!
      if provider.nil?
        raise AssistantError, "Assistant does not support the model #{chat_model}"
      end

      if chat_history.empty?
        raise AssistantError, "Assistant cannot respond to an empty chat"
      end

      unless chat_history.last&.user?
        raise AssistantError, "Assistant can only respond to user messages"
      end
    end
end
