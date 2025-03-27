require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @chat = chats(:two)
    @message = @chat.messages.create!(
      type: "UserMessage",
      content: "Help me with my finances",
      ai_model: "gpt-4o"
    )
    @assistant = Assistant.for_chat(@chat)
    @provider = mock
    @assistant.expects(:get_model_provider).with("gpt-4o").returns(@provider)
  end

  test "responds to basic prompt" do
    text_chunk = Provider::Openai::ChatResponseProcessor::StreamChunk.new(type: "output_text", data: "Hello from assistant")
    response_chunk = Provider::Openai::ChatResponseProcessor::StreamChunk.new(
      type: "response",
      data:  Assistant::Provideable::ChatResponse.new(
        id: "1",
        model: "gpt-4o",
        messages: [
          Assistant::Provideable::ChatResponseMessage.new(
            id: "1",
            content: "Hello from assistant",
          )
        ],
        functions: []
      )
    )

    @provider.expects(:chat_response).with do |message, **options|
      options[:streamer].call(text_chunk)
      options[:streamer].call(response_chunk)
      true
    end

    assert_difference "AssistantMessage.count", 1 do
      @assistant.respond_to(@message)
    end
  end

  test "responds with tool function calls" do
    function_request_chunk = Provider::Openai::ChatResponseProcessor::StreamChunk.new(type: "function_request", data: "get_net_worth")
    text_chunk = Provider::Openai::ChatResponseProcessor::StreamChunk.new(type: "output_text", data: "Your net worth is $124,200")
    response_chunk = Provider::Openai::ChatResponseProcessor::StreamChunk.new(
      type: "response",
      data: Assistant::Provideable::ChatResponse.new(
        id: "1",
        model: "gpt-4o",
        messages: [
          Assistant::Provideable::ChatResponseMessage.new(
            id: "1",
            content: "Your net worth is $124,200",
          )
        ],
        functions: [
          Assistant::Provideable::ChatResponseFunctionExecution.new(
            id: "1",
            call_id: "1",
            name: "get_net_worth",
            arguments: "{}",
            result: "$124,200"
          )
        ]
      )
    )

    @provider.expects(:chat_response).with do |message, **options|
      options[:streamer].call(function_request_chunk)
      options[:streamer].call(text_chunk)
      options[:streamer].call(response_chunk)
      true
    end

    assert_difference "AssistantMessage.count", 1 do
      @assistant.respond_to(@message)
      message = @chat.messages.ordered.where(type: "AssistantMessage").last
      assert_equal 1, message.tool_calls.size
    end
  end
end
