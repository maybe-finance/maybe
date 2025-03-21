class Chat < ApplicationRecord
  include Debuggable

  belongs_to :user

  has_one :viewer, class_name: "User", foreign_key: :last_viewed_chat_id, dependent: :nullify # "Last chat user has viewed"
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  class << self
    def create_from_prompt!(prompt, developer_prompt: nil)
      create!(
        title: prompt.first(20),
        messages: [
          Message.new(kind: "text", role: "developer", content: developer_prompt || default_developer_prompt),
          Message.new(kind: "text", role: "user", content: prompt)
        ]
      )
    end

    def default_developer_prompt
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

  def assistant
    @assistant ||= Assistant.for_chat(self)
  end
end
