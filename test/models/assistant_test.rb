require "test_helper"
require "ostruct"

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
  end

  test "responds to basic prompt" do
    @assistant.expects(:get_model_provider).with("gpt-4o").returns(@provider)

    text_chunk = OpenStruct.new(type: "output_text", data: "Hello from assistant")
    response_chunk = OpenStruct.new(
      type: "response",
      data: OpenStruct.new(
        id: "1",
        model: "gpt-4o",
        messages: [ OpenStruct.new(id: "1", output_text: "Hello from assistant") ],
        function_requests: []
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
    # We expect 2 total instances of ChatStreamer (initial response + follow up with tool call results)
    @assistant.expects(:get_model_provider).with("gpt-4o").returns(@provider).twice

    # Only first provider call executes function
    Assistant::Function::GetAccounts.any_instance.stubs(:call).returns("test value")

    # Call #1: Function requests
    call1_response_chunk = OpenStruct.new(
      type: "response",
      data: OpenStruct.new(
        id: "1",
        model: "gpt-4o",
        messages: [],
        function_requests: [
          OpenStruct.new(
            id: "1",
            call_id: "1",
            function_name: "get_accounts",
            function_args: "{}",
          )
        ]
      )
    )

    # Call #2: Text response (that uses function results)
    call2_text_chunk = OpenStruct.new(type: "output_text", data: "Your net worth is $124,200")
    call2_response_chunk = OpenStruct.new(type: "response", data: OpenStruct.new(
      id: "2",
      model: "gpt-4o",
      messages: [ OpenStruct.new(id: "1", output_text: "Your net worth is $124,200") ],
      function_requests: [],
      function_results: [
        OpenStruct.new(
          provider_id: "1",
          provider_call_id: "1",
          name: "get_accounts",
          arguments: "{}",
          result: "test value"
        )
      ],
      previous_response_id: "1"
    ))

    @provider.expects(:chat_response).with do |message, **options|
      options[:streamer].call(call1_response_chunk)
      options[:streamer].call(call2_text_chunk)
      options[:streamer].call(call2_response_chunk)
      true
    end.returns(nil)

    assert_difference "AssistantMessage.count", 1 do
      @assistant.respond_to(@message)
      message = @chat.messages.ordered.where(type: "AssistantMessage").last
      assert_equal 1, message.tool_calls.size
    end
  end
end
