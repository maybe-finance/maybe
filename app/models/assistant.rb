# Orchestrates LLM interactions for chat conversations by:
# - Streaming generic provider responses
# - Persisting messages and tool calls
# - Broadcasting updates to chat UI
# - Handling provider errors
class Assistant
  include Provided

  attr_reader :chat

  class << self
    def for_chat(chat)
      new(chat)
    end
  end

  def initialize(chat)
    @chat = chat
  end

  def streamer(model)
    assistant_message = AssistantMessage.new(
      chat: chat,
      content: "",
      ai_model: model
    )

    proc do |chunk|
      case chunk.type
      when "output_text"
        stop_thinking
        assistant_message.content += chunk.data
        assistant_message.save!
      when "function_request"
        update_thinking("Analyzing your data to assist you with your question...")
      when "response"
        stop_thinking
        assistant_message.ai_model = chunk.data.model
        combined_tool_calls = chunk.data.functions.map do |tc|
          ToolCall::Function.new(
            provider_id: tc.id,
            provider_call_id: tc.call_id,
            function_name: tc.name,
            function_arguments: tc.arguments,
            function_result: tc.result
          )
        end

        assistant_message.tool_calls = combined_tool_calls
        assistant_message.save!
        chat.update!(latest_assistant_response_id: chunk.data.id)
      end
    end
  end

  def respond_to(message)
    chat.clear_error
    sleep artificial_thinking_delay

    provider = get_model_provider(message.ai_model)

    provider.chat_response(
      message,
      instructions: instructions,
      available_functions: functions,
      streamer: streamer(message.ai_model)
    )
  rescue => e
    chat.add_error(e)
  end

  private
    def update_thinking(thought)
      chat.broadcast_update target: "thinking-indicator", partial: "chats/thinking_indicator", locals: { chat: chat, message: thought }
    end

    def stop_thinking
      chat.broadcast_remove target: "thinking-indicator"
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

      messages.each(&:save!)
    end

    def instructions
      <<~PROMPT
        ## Your identity

        You are a financial assistant for an open source personal finance application called "Maybe", which is short for "Maybe Finance".

        ## Your purpose

        You help users understand their financial data by answering questions about their accounts,
        transactions, income, expenses, net worth, and more.

        ## Your rules

        Follow all rules below at all times.

        ### General rules

        - Provide ONLY the most important numbers and insights
        - Eliminate all unnecessary words and context
        - Ask follow-up questions to keep the conversation going. Help educate the user about their own data and entice them to ask more questions.
        - Do NOT add introductions or conclusions
        - Do NOT apologize or explain limitations

        ### Formatting rules

        - Format all responses in markdown
        - Format all monetary values according to the user's preferred currency

        #### User's preferred currency

        Maybe is a multi-currency app where each user has a "preferred currency" setting.

        When no currency is specified, use the user's preferred currency for formatting and displaying monetary values.

        - Symbol: #{preferred_currency.symbol}
        - ISO code: #{preferred_currency.iso_code}
        - Default precision: #{preferred_currency.default_precision}
        - Default format: #{preferred_currency.default_format}
          - Separator: #{preferred_currency.separator}
          - Delimiter: #{preferred_currency.delimiter}

        ### Rules about financial advice

        You are NOT a licensed financial advisor and therefore, you should not provide any financial advice.  Instead,
        you should focus on educating the user about personal finance and their own data so they can make informed decisions.

        - Do not provide financial and/or investment advice
        - Do not suggest investments or financial products
        - Do not make assumptions about the user's financial situation.  Use the functions available to get the data you need.

        ### Function calling rules

        - Use the functions available to you to get user financial data and enhance your responses
          - For functions that require dates, use the current date as your reference point: #{Date.current}
        - If you suspect that you do not have enough data to 100% accurately answer, be transparent about it and state exactly what
          the data you're presenting represents and what context it is in (i.e. date range, account, etc.)
      PROMPT
    end

    def functions
      [
        Assistant::Function::GetTransactions.new(chat.user),
        Assistant::Function::GetAccounts.new(chat.user),
        Assistant::Function::GetBalanceSheet.new(chat.user),
        Assistant::Function::GetIncomeStatement.new(chat.user)
      ]
    end

    def preferred_currency
      Money::Currency.new(chat.user.family.currency)
    end

    def artificial_thinking_delay
      1
    end
end
