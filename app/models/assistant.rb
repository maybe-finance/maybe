class Assistant
  include Provided

  AssistantError = Class.new(StandardError)

  attr_reader :chat

  class << self
    def for_chat(chat)
      new(chat)
    end
  end

  def initialize(chat)
    @chat = chat
  end

  def respond_to(message)
    provider = get_model_provider(message.ai_model)

    response = provider.chat_response(
      model: message.ai_model,
      instructions: instructions,
      chat_history: chat_history,
      functions: functions
    )

    if response.success?
      process_response_artifacts(response.data)
    else
      chat.update!(error: response.error)
      raise AssistantError, "Assistant failed to respond to user: #{response.error}"
    end
  end

  private
    def chat_history
      chat.messages.where.not(debug: true).ordered
    end

    def process_response_artifacts(data)
      messages = data.messages.map do |message|
        AssistantMessage.new(
          chat: chat,
          content: message.content,
          provider_id: message.id,
          ai_model: data.model,
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

      messages.each do |msg|
        msg.valid?
        puts msg.errors.full_messages

        msg.tool_calls.each do |tool_call|
          tool_call.valid?
          puts tool_call.errors.full_messages
        end
      end

      messages.each(&:save!)
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

    def functions
      [
        Assistant::Functions::GetBalanceSheet.new,
        Assistant::Functions::GetIncomeStatement.new,
        Assistant::Functions::GetExpenseCategories.new,
        Assistant::Functions::GetAccountBalances.new,
        Assistant::Functions::GetTransactions.new,
        Assistant::Functions::ComparePeriods.new
      ]
    end
end
