class Provider::Openai::AutoCategorizer
  def initialize(client, transactions: [], user_categories: [])
    @client = client
    @transactions = transactions
    @user_categories = user_categories
  end

  def auto_categorize
    response = client.responses.create(parameters: {
      model: "gpt-4.1-mini",
      input: [ { role: "developer", content: developer_message } ],
      text: {
        format: {
          type: "json_schema",
          name: "auto_categorize_personal_finance_transactions",
          strict: true,
          schema: json_schema
        }
      },
      instructions: instructions
    })

    Rails.logger.info("Tokens used to auto-categorize transactions: #{response.dig("usage").dig("total_tokens")}")

    build_response(extract_categorizations(response))
  end

  private
    attr_reader :client, :transactions, :user_categories

    AutoCategorization = Provider::LlmConcept::AutoCategorization

    def build_response(categorizations)
      categorizations.map do |categorization|
        AutoCategorization.new(
          transaction_id: categorization.dig("transaction_id"),
          category_name: normalize_category_name(categorization.dig("category_name")),
        )
      end
    end

    def normalize_category_name(category_name)
      return nil if category_name == "null"

      category_name
    end

    def extract_categorizations(response)
      response_json = JSON.parse(response.dig("output")[0].dig("content")[0].dig("text"))
      response_json.dig("categorizations")
    end

    def json_schema
      {
        type: "object",
        properties: {
          categorizations: {
            type: "array",
            description: "An array of auto-categorizations for each transaction",
            items: {
              type: "object",
              properties: {
                transaction_id: {
                  type: "string",
                  description: "The internal ID of the original transaction",
                  enum: transactions.map { |t| t[:id] }
                },
                category_name: {
                  type: "string",
                  description: "The matched category name of the transaction, or null if no match",
                  enum: [ *user_categories.map { |c| c[:name] }, "null" ]
                }
              },
              required: [ "transaction_id", "category_name" ],
              additionalProperties: false
            }
          }
        },
        required: [ "categorizations" ],
        additionalProperties: false
      }
    end

    def developer_message
      <<~MESSAGE.strip_heredoc
        Here are the user's available categories in JSON format:

        ```json
        #{user_categories.to_json}
        ```

        Use the available categories to auto-categorize the following transactions:

        ```json
        #{transactions.to_json}
        ```
      MESSAGE
    end

    def instructions
      <<~INSTRUCTIONS.strip_heredoc
        You are an assistant to a consumer personal finance app.  You will be provided a list
        of the user's transactions and a list of the user's categories.  Your job is to auto-categorize
        each transaction.

        Closely follow ALL the rules below while auto-categorizing:

        - Return 1 result per transaction
        - Correlate each transaction by ID (transaction_id)
        - Attempt to match the most specific category possible (i.e. subcategory over parent category)
        - Category and transaction classifications should match (i.e. if transaction is an "expense", the category must have classification of "expense")
        - If you don't know the category, return "null"
          - You should always favor "null" over false positives
          - Be slightly pessimistic.  Only match a category if you're 60%+ confident it is the correct one.
        - Each transaction has varying metadata that can be used to determine the category
          - Note: "hint" comes from 3rd party aggregators and typically represents a category name that
            may or may not match any of the user-supplied categories
      INSTRUCTIONS
    end
end
