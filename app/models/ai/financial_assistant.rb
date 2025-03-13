module Ai
  class FinancialAssistant
    attr_reader :family, :client

    def initialize(family, client: nil)
      @family = family
      @client = client || OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
    end

    def query(question, chat_history = nil)
      # Log the system prompt in debug mode
      if Ai::DebugMode.enabled? && @chat
        Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: System prompt", { prompt: system_prompt })
      end

      # Build messages array with chat history if provided
      messages = [ { role: "system", content: system_prompt } ]

      if chat_history.present?
        # Add previous messages from chat history, excluding system messages
        messages.concat(
          chat_history
            .conversation
            .ordered
            .map { |msg| { role: msg.role, content: msg.content } }
        )

        # If the last message is not the current question, add it
        if messages.last[:content] != question
          messages << { role: "user", content: question }
        end
      else
        # Just add the current question if no history
        messages << { role: "user", content: question }
      end

      # Log the messages being sent in debug mode
      if Ai::DebugMode.enabled? && @chat
        Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: Messages being sent to AI", { messages: messages })
      end

      response = client.chat(
        parameters: {
          model: "gpt-4o",
          messages: messages,
          tools: financial_function_definitions.map { |func| { type: "function", function: func } },
          tool_choice: "auto",
          temperature: 0.5
        }
      )

      process_response(response, question, messages)
    end

    # Set the chat for debug logging
    def with_chat(chat)
      @chat = chat
      self
    end

    # Define the functions that can be called by GPT
    def financial_function_definitions
      [
        {
          name: "get_balance_sheet",
          description: "Get current balance sheet information including net worth, assets, and liabilities",
          parameters: {
            type: "object",
            properties: {},
            required: []
          }
        },
        {
          name: "get_income_statement",
          description: "Get income statement data for a specific time period",
          parameters: {
            type: "object",
            properties: {
              period: {
                type: "string",
                enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
                description: "The time period for the income statement data"
              }
            },
            required: []
          }
        },
        {
          name: "get_expense_categories",
          description: "Get top expense categories for a specific time period",
          parameters: {
            type: "object",
            properties: {
              period: {
                type: "string",
                enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
                description: "The time period for the expense categories data"
              },
              limit: {
                type: "integer",
                description: "Number of top categories to return",
                default: 5
              }
            },
            required: []
          }
        },
        {
          name: "get_account_balances",
          description: "Get balances for all accounts or by account type",
          parameters: {
            type: "object",
            properties: {
              account_type: {
                type: "string",
                enum: [ "asset", "liability", "all" ],
                description: "Type of accounts to get balances for"
              }
            },
            required: []
          }
        },
        {
          name: "get_transactions",
          description: "Get transactions filtered by date range and/or category",
          parameters: {
            type: "object",
            properties: {
              start_date: {
                type: "string",
                format: "date",
                description: "Start date for transactions (YYYY-MM-DD)"
              },
              end_date: {
                type: "string",
                format: "date",
                description: "End date for transactions (YYYY-MM-DD)"
              },
              category_name: {
                type: "string",
                description: "Filter transactions by category name"
              },
              limit: {
                type: "integer",
                description: "Maximum number of transactions to return",
                default: 10
              }
            },
            required: []
          }
        },
        {
          name: "compare_periods",
          description: "Compare financial data between two periods",
          parameters: {
            type: "object",
            properties: {
              period1: {
                type: "string",
                enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
                description: "First period for comparison"
              },
              period2: {
                type: "string",
                enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
                description: "Second period for comparison"
              }
            },
            required: [ "period1", "period2" ]
          }
        }
      ]
    end

    private

      def process_response(response, original_question, messages)
        message = response.dig("choices", 0, "message")

        # Log the raw response in debug mode
        if Ai::DebugMode.enabled? && @chat
          Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: Raw AI response", {
            response_type: message["tool_calls"] ? "function_call" : "direct_content",
            content: message["content"]
          })
        end

        # If there are no function calls, ensure the direct response is concise
        return message["content"] unless message["tool_calls"]

        # Handle function calls
        function_calls = message["tool_calls"]

        # Log the function calls in debug mode
        if Ai::DebugMode.enabled? && @chat
          debug_function_calls = function_calls.map do |call|
            {
              function_name: call["function"]["name"],
              arguments: JSON.parse(call["function"]["arguments"])
            }
          end

          Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: Function calls", { function_calls: debug_function_calls })
        end

        function_results = execute_function_calls(function_calls)

        # Log the function results in debug mode
        if Ai::DebugMode.enabled? && @chat
          debug_results = function_calls.map.with_index do |call, i|
            {
              function_name: call["function"]["name"],
              result: function_results[i]
            }
          end

          Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: Function results", { results: debug_results })
        end

        # Continue the conversation with function results
        follow_up_messages = messages.dup

        # Add the assistant's response with function calls
        follow_up_messages << message

        # Add the function results
        function_results.each_with_index do |result, index|
          follow_up_messages << {
            role: "tool",
            tool_call_id: function_calls[index]["id"],
            name: function_calls[index]["function"]["name"],
            content: result.to_json
          }
        end

        # Add a reminder to be concise
        follow_up_messages << {
          role: "system",
          content: "CRITICAL: Eliminate all unnecessary words."
        }

        # Log the follow-up request in debug mode
        if Ai::DebugMode.enabled? && @chat
          Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: Follow-up request", { messages: follow_up_messages })
        end

        follow_up_response = client.chat(
          parameters: {
            model: "gpt-4o",
            messages: follow_up_messages,
            temperature: 0.5
          }
        )

        # Log the final response in debug mode
        final_content = follow_up_response.dig("choices", 0, "message", "content")
        if Ai::DebugMode.enabled? && @chat
          Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: Final response", { content: final_content })
        end

        # Return the final response
        final_content
      end

      def execute_function_calls(function_calls)
        function_calls.map do |call|
          function_name = call["function"]["name"]
          arguments = JSON.parse(call["function"]["arguments"])

          # Log the function execution in debug mode
          if Ai::DebugMode.enabled? && @chat
            Ai::DebugMode.log_to_chat(@chat, "🐞 DEBUG: Executing function", {
              function: function_name,
              arguments: arguments
            })
          end

          result = case function_name
          when "get_balance_sheet"
            execute_get_balance_sheet(arguments)
          when "get_income_statement"
            execute_get_income_statement(arguments)
          when "get_expense_categories"
            execute_get_expense_categories(arguments)
          when "get_account_balances"
            execute_get_account_balances(arguments)
          when "get_transactions"
            execute_get_transactions(arguments)
          when "compare_periods"
            execute_compare_periods(arguments)
          else
            { error: "Unknown function: #{function_name}" }
          end

          result
        end
      end

      # Execute the get_balance_sheet function
      def execute_get_balance_sheet(params = {})
        balance_sheet = BalanceSheet.new(family)
        balance_sheet.to_ai_readable_hash
      end

      # Execute the get_income_statement function
      def execute_get_income_statement(params = {})
        income_statement = IncomeStatement.new(family)
        period = get_period_from_param(params["period"])
        income_statement.to_ai_readable_hash(period: period)
      end

      # Execute the get_expense_categories function
      def execute_get_expense_categories(params = {})
        income_statement = IncomeStatement.new(family)
        period = get_period_from_param(params["period"])
        limit = params["limit"] || 5

        expense_data = income_statement.expense_totals(period: period)

        top_categories = expense_data.category_totals
          .reject { |ct| ct.category.subcategory? }
          .sort_by { |ct| -ct.total }
          .take(limit)
          .map do |ct|
            {
              name: ct.category.name,
              amount: format_currency(ct.total),
              percentage: ct.weight.round(2)
            }
          end

        {
          period: {
            start_date: period.start_date.to_s,
            end_date: period.end_date.to_s
          },
          total_expenses: format_currency(expense_data.total),
          top_categories: top_categories,
          currency: family.currency
        }
      end

      # Execute the get_account_balances function
      def execute_get_account_balances(params = {})
        account_type = params["account_type"] || "all"
        balance_sheet = BalanceSheet.new(family)

        accounts = case account_type
        when "asset"
          balance_sheet.account_groups("asset")
        when "liability"
          balance_sheet.account_groups("liability")
        else
          balance_sheet.account_groups
        end

        account_data = accounts.flat_map do |group|
          group.accounts.map do |account|
            {
              name: account.name,
              type: account.accountable_type,
              balance: format_currency(account.balance),
              classification: account.classification
            }
          end
        end

        {
          as_of_date: Date.today.to_s,
          currency: family.currency,
          accounts: account_data
        }
      end

      # Execute the get_transactions function
      def execute_get_transactions(params = {})
        start_date = params["start_date"] ? Date.parse(params["start_date"]) : 30.days.ago.to_date
        end_date = params["end_date"] ? Date.parse(params["end_date"]) : Date.today
        category_name = params["category_name"]
        limit = params["limit"] || 10

        transactions_query = family.transactions.active.in_period(Period.new(start_date: start_date, end_date: end_date))

        if category_name.present?
          # Try to find an exact match first
          category = family.categories.find_by(name: category_name)

          # If no exact match, try fuzzy matching
          unless category
            # Try case-insensitive contains matching
            categories = family.categories.where("LOWER(name) LIKE ?", "%#{category_name.downcase}%")

            # If still no match, try common synonyms
            if categories.empty?
              synonyms = {
                "food" => [ "grocery", "groceries", "supermarket", "dining", "restaurant", "meal" ],
                "groceries" => [ "food", "grocery", "supermarket" ],
                "dining" => [ "restaurant", "food", "eating out", "meal" ],
                "utilities" => [ "utility", "bills", "electricity", "water", "gas" ],
                "transportation" => [ "travel", "car", "bus", "transit", "commute" ],
                "shopping" => [ "retail", "clothes", "merchandise" ]
                # Add more common synonyms as needed
              }

              matched_categories = []
              synonyms.each do |formal_term, informal_terms|
                if category_name.downcase == formal_term.downcase ||
                   informal_terms.any? { |term| category_name.downcase.include?(term.downcase) }
                  matched_categories += family.categories.where("LOWER(name) LIKE ?", "%#{formal_term.downcase}%")
                end
              end

              categories = matched_categories.uniq if matched_categories.any?
            end

            # Use the first matching category if any were found
            category = categories.first if categories.any?
          end

          # If we found a category through any matching method, filter by it
          if category
            transactions_query = transactions_query.where(category_id: category.id)
          end
        end

        # Use eager loading to avoid N+1 queries and ensure all attributes are available
        transactions_query = transactions_query.includes(:account_entry, :category, :merchant)

        # Specify the table name explicitly to avoid ambiguous column reference
        transactions = transactions_query.order("account_entries.date DESC").limit(limit)

        transaction_data = transactions.map do |transaction|
          # Access the date through the entry association
          entry = transaction.account_entry
          {
            date: entry.date,
            name: entry.name,
            amount: format_currency(entry.amount),
            category: transaction.category&.name || "Uncategorized",
            merchant: transaction.merchant&.name
          }
        end

        {
          period: {
            start_date: start_date.to_s,
            end_date: end_date.to_s
          },
          transactions: transaction_data,
          count: transaction_data.size,
          currency: family.currency,
          search_info: {
            category_query: category_name,
            matched_category: category&.name
          }
        }
      end

      # Execute the compare_periods function
      def execute_compare_periods(params = {})
        period1 = get_period_from_param(params["period1"])
        period2 = get_period_from_param(params["period2"])

        income_statement = IncomeStatement.new(family)

        period1_data = {
          income: income_statement.income_totals(period: period1),
          expenses: income_statement.expense_totals(period: period1)
        }

        period2_data = {
          income: income_statement.income_totals(period: period2),
          expenses: income_statement.expense_totals(period: period2)
        }

        # Calculate differences
        income_diff = period1_data[:income].total - period2_data[:income].total
        expenses_diff = period1_data[:expenses].total - period2_data[:expenses].total
        net_income_diff = income_diff - expenses_diff

        # Calculate percentage changes
        income_pct_change = period2_data[:income].total > 0 ? (income_diff / period2_data[:income].total.to_f * 100).round(2) : 0
        expenses_pct_change = period2_data[:expenses].total > 0 ? (expenses_diff / period2_data[:expenses].total.to_f * 100).round(2) : 0

        {
          period1: {
            name: period_name(params["period1"]),
            start_date: period1.start_date.to_s,
            end_date: period1.end_date.to_s,
            total_income: format_currency(period1_data[:income].total),
            total_expenses: format_currency(period1_data[:expenses].total),
            net_income: format_currency(period1_data[:income].total - period1_data[:expenses].total)
          },
          period2: {
            name: period_name(params["period2"]),
            start_date: period2.start_date.to_s,
            end_date: period2.end_date.to_s,
            total_income: format_currency(period2_data[:income].total),
            total_expenses: format_currency(period2_data[:expenses].total),
            net_income: format_currency(period2_data[:income].total - period2_data[:expenses].total)
          },
          differences: {
            income: format_currency(income_diff),
            income_percent: income_pct_change,
            expenses: format_currency(expenses_diff),
            expenses_percent: expenses_pct_change,
            net_income: format_currency(net_income_diff)
          },
          currency: family.currency
        }
      end

      # Helper to convert period string to a Period object
      def get_period_from_param(period_param)
        case period_param
        when "current_month"
          Period.current_month
        when "previous_month"
          Period.previous_month
        when "year_to_date"
          Period.year_to_date
        when "previous_year"
          Period.previous_year
        else
          Period.current_month
        end
      end

      # Helper to get human-readable period name
      def period_name(period_param)
        case period_param
        when "current_month"
          "Current Month"
        when "previous_month"
          "Previous Month"
        when "year_to_date"
          "Year to Date"
        when "previous_year"
          "Previous Year"
        else
          "Custom Period"
        end
      end

      # Format currency values consistently for AI display
      def format_currency(amount, currency = family.currency)
        Money.new(amount, currency).format
      end

      # System prompt for the GPT model
      def system_prompt
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

      # Ensure the response is concise by truncating if necessary
      def ensure_concise_response(content)
        return "" if content.nil? || content.empty?

        # Split the content into sentences
        sentences = content.split(/(?<=[.!?])\s+/)

        # Handle case where regex doesn't match (e.g., single sentence without ending punctuation)
        sentences = [ content ] if sentences.empty?

        # Take only the first 3 sentences maximum
        sentences = sentences[0..2]

        # Join the sentences back together
        truncated = sentences.join(" ")

        # Further limit by word count (75 words maximum)
        words = truncated.split(/\s+/)
        if words.length > 75
          truncated = words[0...75].join(" ")
          # Ensure the truncated content ends with proper punctuation
          truncated = truncated.strip
          truncated += "." unless truncated.end_with?(".", "!", "?")
        end

        truncated
      end
  end
end
