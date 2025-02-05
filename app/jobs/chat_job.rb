class ChatJob < ApplicationJob
  queue_as :default

  def perform(chat_id, message_id)
    chat = Chat.find(chat_id)
    nil if chat.nil?

    message = chat.messages.find(message_id)
    openai_client = OpenAI::Client.new

    begin
      viability = determine_viability(openai_client, chat)

      if !viability["content_contains_answer"]
        handle_non_viable_conversation(openai_client, chat, message, viability)
      else
        generate_response_content(openai_client, chat, message)
      end
    rescue => e
      Rails.logger.error "ChatJob Error: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      message.update(content: "I encountered an error processing your request. Please try again.")
      update_conversation(message, chat)
    end
  end

  private
    def make_openai_request(openai_client, parameters, chat, context = "")
      begin
        Rails.logger.info "Making OpenAI request - Context: #{context}"
        Rails.logger.debug "Request parameters: #{parameters.inspect}"

        response = openai_client.chat(parameters: parameters)

        Rails.logger.debug "OpenAI Response: #{response.inspect}"

        if response["error"].present?
          Rails.logger.error "OpenAI API Error - Context: #{context}"
          Rails.logger.error "Error details: #{response["error"].inspect}"
          raise "OpenAI API Error: #{response["error"]["message"]}"
        end

        response
      rescue => e
        Rails.logger.error "OpenAI Request Failed - Context: #{context}"
        Rails.logger.error "Error: #{e.class} - #{e.message}"
        Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
        raise e
      end
    end

    def determine_viability(openai_client, chat)
      chat_history = chat.messages.where.not(content: [ nil, "" ]).where.not(content: "...").where.not(role: "log").order(:created_at)

      messages = chat_history.map do |message|
        { role: message.role, content: message.content }
      end

      total_content_length = messages.sum { |message| message[:content]&.length.to_i }

      while total_content_length > 10000
        oldest_message = messages.shift
        total_content_length -= oldest_message[:content]&.length.to_i

        if total_content_length <= 8000
          messages.unshift(oldest_message) # Put the message back if the total length is within the limit
          break
        end
      end

      # Remove the last message, as it is the one we are trying to answer
      messages.pop if messages.last[:role] == "user"

      message = chat.messages.where(role: "user").order(created_at: :asc).last

      parameters = {
        model: "o3-mini",
        messages: [
          { role: "developer", content: "You are a highly intelligent certified financial advisor tasked with helping the customer make wise financial decisions based on real data.\n\nHere's some contextual information:\n#{messages}" },
          { role: "assistant", content: <<-ASSISTANT.strip_heredoc },
            Instructions: First, determine the user's intent from the following prioritized list:
            1. reply: the user is replying to a previous message
            2. education: the user is trying to learn more about personal finance
            3. metrics: the user wants to know specific financial metrics
            4. transactional: the user wants to know about specific transactions
            5. investing: the user has a specific question about investing
            6. accounts: the user has a specific question about their accounts
            7. system: the user wants to know how to do something within the product

            Remember:
            - If we need to query data, content_contains_answer should be false
            - For metrics queries, resolution should be to query metrics table
            - For stock/security questions, verify data availability

            Respond in JSON format with these fields:
            - user_intent: string (the intent from above list)
            - intent_reasoning: string (brief reason for intent)
            - metric_name: string (only for metrics intent)
            - content_contains_answer: boolean
            - justification: string (why content is/isn't sufficient)
            - resolve: string (data needed to resolve)
          ASSISTANT
          { role: "user", content: "User inquiry: #{message.content}" }
        ],
        max_completion_tokens: 2000,
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "intent_analysis",
            schema: {
              type: "object",
              properties: {
                user_intent: {
                  type: "string",
                  enum: [ "reply", "education", "metrics", "transactional", "investing", "accounts", "system" ]
                },
                intent_reasoning: {
                  type: "string",
                  maxLength: 100
                },
                metric_name: {
                  type: "string"
                },
                content_contains_answer: {
                  type: "boolean"
                },
                justification: {
                  type: "string",
                  maxLength: 150
                },
                resolve: {
                  type: "string",
                  maxLength: 150
                }
              },
              required: [ "user_intent", "intent_reasoning", "content_contains_answer", "justification", "resolve" ]
            }
          }
        }
      }

      response = make_openai_request(openai_client, parameters, chat, "Determining viability")

      raw_response = response.dig("choices", 0, "message", "content")

      chat.messages.create!(
        log: raw_response,
        user: nil,
        role: "log"
      )

      begin
        JSON.parse(raw_response)
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse OpenAI response as JSON"
        Rails.logger.error "Raw response: #{raw_response.inspect}"
        Rails.logger.error "Error: #{e.message}"
        raise e
      end
    end

    def handle_non_viable_conversation(openai_client, chat, message, viability)
      if viability["user_intent"] == "developer"
        message.update(content: "I'm sorry, I'm not able to help with that right now.")
        update_conversation(message, chat)
      else
        message.update(status: "data")
        update_conversation(message, chat)

        build_sql(openai_client, chat, viability["user_intent"])
        viability = determine_viability(openai_client, chat)

        if viability["content_contains_answer"]
          message.update(status: "processing")
          update_conversation(message, chat)

          generate_response_content(openai_client, chat, message)
        else
          message.update(content: "I'm sorry, I wasn't able to find the necessary information in the database.")
          update_conversation(message, chat)
        end
      end
    end

    def generate_response_content(openai_client, chat, message)
      response_content = build_answer(openai_client, chat, message)
      message.update(content: response_content, status: "done")
      update_conversation(message, chat)
    end

    def update_conversation(message, chat)
      chat.broadcast_append_to(
        chat,
        target: "chat_messages",
        partial: "chats/message",
        locals: { message: message }
      )
    end

    def build_sql(openai_client, chat, sql_intent)
      # Load schema file from config/llmschema.yml
      schema = YAML.load_file(Rails.root.join("config", "llm_schema.yml"))
      sql_scopes = YAML.load_file(Rails.root.join("config", "llm_sql.yml"))
      scope = sql_scopes["intent"].find { |intent| intent["name"] == sql_intent }["scope"]
      core = sql_scopes["core"].first["scope"]

      family_id = chat.user.family_id
      accounts_ids = chat.user.family.accounts.pluck(:id)

      # Get the most recent user message
      message = chat.messages.where(role: "user").order(created_at: :asc).last

      # Get the last log message from the assistant and get the 'resolve' value (log should be converted to a hash from JSON)
      last_log = chat.messages.where(role: "log").where.not(log: nil).order(created_at: :desc).first
      last_log_json = JSON.parse(last_log.log)
      resolve_value = last_log_json["resolve"]

      parameters = {
        model: "o3-mini",
        messages: [
          { role: "developer", content: "You are an expert in SQL and Postgres." },
          { role: "assistant", content: <<-ASSISTANT.strip_heredoc }
            #{schema}

            family_id = #{family_id}
            account_ids = #{accounts_ids}

            Given the preceding Postgres database schemas and variables, write an SQL query that answers the question '#{message.content}'.

            According to the last log message, this is what is needed to answer the question: '#{resolve_value}'.

            Scope:
            #{core}
            #{scope}

            Important query writing rules:
            1. When dealing with dates:
               - Use "date <= CURRENT_DATE" instead of "date = CURRENT_DATE" to get more data
               - Order by date DESC and use LIMIT to get the most recent data
               - For date ranges, use inclusive bounds (BETWEEN or <= and >=)
            2. For metrics/balances/holdings:
               - Always order by date DESC to get most recent data first
               - Use appropriate LIMIT clauses to get enough data for context
               - Consider using window functions for time-based analysis
            3. Security:
               - Always cast UUIDs explicitly in WHERE clauses
               - Use the provided family_id and account_ids variables
            4. Performance:
               - Add appropriate LIMIT clauses (usually 500 for historical data, 1 for current values)
               - Use indexes effectively (date, family_id, and kind are indexed)

            Respond exclusively with the SQL query, no preamble or explanation, beginning with 'SELECT' and ending with a semicolon.

            Do NOT include "```sql" or "```" in your response.
          ASSISTANT
        ],
        max_completion_tokens: 2048
      }

      response = make_openai_request(openai_client, parameters, chat, "Building SQL query")
      sql_content = response.dig("choices", 0, "message", "content")

      markdown_reply = chat.messages.create!(
        log: sql_content,
        user: nil,
        role: "assistant",
        hidden: true
      )

      results = ReplicaQueryService.execute(query: sql_content, family_id: family_id)

      # Convert results to markdown
      markdown = "| #{results.fields.join(' | ')} |\n| #{results.fields.map { |f| '-' * f.length }.join(' | ')} |\n"
      results.each do |row|
        markdown << "| #{row.values.join(' | ')} |\n"
      end

      if results.first.nil?
        response_content = "I wasn't able to find any relevant information in the database."
        markdown_reply.update(content: response_content)
      else
        markdown_reply.update(content: markdown)
      end
    end

    def build_answer(openai_client, chat, message)
      conversation_history = chat.messages.where.not(content: [ nil, "" ]).where.not(content: "...").where.not(role: "log").order(:created_at)

      messages = conversation_history.map do |message|
        if message.role == "assistant" && message.hidden
          { role: message.role, content: "HIDDEN: The user does not see this content in their message history, so you'll need to repeat the data if you reference it.\n\n#{message.content}" }
        else
          { role: message.role, content: message.content }
        end
      end

      total_content_length = messages.sum { |message| message[:content]&.length.to_i }

      while total_content_length > 10000
        oldest_message = messages.shift
        total_content_length -= oldest_message[:content]&.length.to_i

        if total_content_length <= 8000
          messages.unshift(oldest_message) # Put the message back if the total length is within the limit
          break
        end
      end

      message = chat.messages.where(role: "user").order(created_at: :asc).last

      # Get the last log message from the assistant and get the 'resolve' value (log should be converted to a hash from JSON)
      last_log = chat.messages.where(role: "log").where.not(log: nil).order(created_at: :desc).first
      last_log_json = JSON.parse(last_log.log)
      resolve_value = last_log_json["resolve"]

      text_string = ""

      parameters = {
        model: "o3-mini",
        messages: [
          { role: "developer", content: "You are a highly intelligent certified financial advisor/teacher/mentor tasked with helping the customer make wise financial decisions based on real data. You should always tune your question to the interest & knowledge of the peron, breaking down the problem into simpler parts until it's at just the right level for them.\n\nUse only the information in the conversation to construct your response." },
          { role: "assistant", content: <<-ASSISTANT.strip_heredoc },
          Here is information about the user and their financial situation, so you understand them better:
          - Country: #{chat.user.family.country}
          - Preferred language: #{chat.user.family.locale}
          - Preferred currency: #{chat.user.family.currency}
          - Preferred date format: #{chat.user.family.date_format}

            Follow these rules as you create your answer:
          - Keep responses very brief and to the point, unless the user asks for more details.
          - Response should be in markdown format, adding bold or italics as needed.
          - If you output a formula, wrap it in backticks.
          - Do not output any SQL, IDs or UUIDs.
          - Data should be human readable.
          - Dates should be long form.
          - If there is no data for the requested date, say there isn't enough data.
          - Don't include pleasantries.
          - Favor putting lists in tabular markdown format, especially if they're long.
          - Currencies should be output with two decimal places and a dollar sign.
          - Use full names for financial products, not abbreviations.
          - Answer truthfully and be specific.
          - If you are doing a calculation, show the formula.
          - If you don't have certain industry data, use the S&P 500 as a proxy.
          - Remember, "accounts" and "transactions" are different things.
          - If you are not absolutely sure what the user is asking, ask them to clarify. Clarity is key.
          - Unless the user explicitly asks for "pending" transactions, you should ignore all transactions where is_pending is true.
          - Try to add helpful observations/insights to your answer.
          - Include additional context and tabular data as helpful, especially if the user is seemingly diving deeper, but never include "ID" columns of any type.
          - Never include any SQL, IDs or UUIDs in your response.

          According to the last log message, this is what is needed to answer the question: '#{resolve_value}'.

          Be sure to output what data you are using to answer the question, and why you are using it.

          ASSISTANT
          *messages
        ],
        max_completion_tokens: 1200,
        stream: proc do |chunks, _bytesize|
          chat.broadcast_remove_to "chat_messages", target: "message_content_loader_#{message.id}"

          if chunks.dig("choices")[0]["delta"].present?
            content = chunks.dig("choices", 0, "delta", "content")
            text_string += content unless content.nil?

            chat.broadcast_append_to "chat_messages", partial: "chats/stream", locals: { text: content }, target: "message_content_#{message.id}"
          end
        end
      }

      begin
        make_openai_request(openai_client, parameters, chat, "Building final answer")
        text_string
      rescue => e
        Rails.logger.error "Failed to build answer"
        Rails.logger.error "Error: #{e.message}"
        raise e
      end
    end
end
