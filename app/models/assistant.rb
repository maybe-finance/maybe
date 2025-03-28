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

  class ToolCaller
    def initialize(functions: [])
      @functions = functions
    end

    def call_function(function_request)
      name = function_request.function_name
      args = JSON.parse(function_request.function_arguments)
      fn = get_function(name)
      result = fn.call(args)

      ToolCall::Function.new(
        provider_id: function_request.provider_id,
        provider_call_id: function_request.provider_call_id,
        function_name: name,
        function_arguments: args,
        function_result: result
      )
    rescue => e
      fn_execution_details = {
        fn_name: name,
        fn_args: args
      }

      message = "Error calling function #{name} with arguments #{args}: #{e.message}"

      raise StandardError.new(message)
    end

    private
      attr_reader :functions

      def get_function(name)
        functions.find { |f| f.name == name }
      end
  end

  def respond_to(message)
    chat.clear_error

    sleep artificial_thinking_delay

    provider = get_model_provider(message.ai_model)

    tool_caller = ToolCaller.new(functions: functions)

    assistant_response = AssistantMessage.new(
      chat: chat,
      content: "",
      ai_model: message.ai_model
    )

    streamer = proc do |chunk|
      case chunk.type
      when "output_text"
        stop_thinking
        assistant_response.content += chunk.data
        assistant_response.save!
      when "response"
        if chunk.data.function_requests.any?
          update_thinking("Analyzing your data to assist you with your question...")

          tool_calls = chunk.data.function_requests.map do |fn_request|
            tool_caller.call_function(fn_request)
          end

          assistant_response.tool_calls = tool_calls
          assistant_response.save!

          provider.chat_response(
            message.content,
            model: message.ai_model,
            instructions: instructions,
            functions: functions.map(&:to_h),
            function_results: tool_calls.map(&:to_h),
            streamer: streamer
          )
        else
          stop_thinking
        end

        chat.update!(latest_assistant_response_id: chunk.data.id)
      end
    end

    provider.chat_response(
      message.content,
      model: message.ai_model,
      instructions: instructions,
      functions: functions.map(&:to_h),
      function_results: [],
      streamer: streamer
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
