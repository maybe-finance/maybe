class Assistant::ResponseStreamer
  def initialize(assistant_message, follow_up_streamer: nil)
    @assistant_message = assistant_message
    @follow_up_streamer = follow_up_streamer
  end

  def call(chunk)
    case chunk.type
    when "output_text"
      assistant_message.content += chunk.data
      assistant_message.save!
    when "response"
      response = chunk.data
      chat.update!(latest_assistant_response_id: response.id)
    end
  end

  private
    attr_reader :assistant_message, :follow_up_streamer

    def chat
      assistant_message.chat
    end

    # If a follow-up streamer is provided, this is the first response to the LLM
    def first_response?
      follow_up_streamer.present?
    end
end
