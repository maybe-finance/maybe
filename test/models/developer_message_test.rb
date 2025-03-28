require "test_helper"

class DeveloperMessageTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
  end

  test "does not broadcast" do
    message = DeveloperMessage.create!(chat: @chat, content: "Some instructions")
    message.update!(content: "updated")

    assert_no_turbo_stream_broadcasts(@chat)
  end

  test "broadcasts if debug mode is enabled" do
    with_env_overrides AI_DEBUG_MODE: "true" do
      message = DeveloperMessage.create!(chat: @chat, content: "Some instructions")
      message.update!(content: "updated")

      streams = capture_turbo_stream_broadcasts(@chat)
      assert_equal 2, streams.size
      assert_equal "append", streams.first["action"]
      assert_equal "messages", streams.first["target"]
      assert_equal "update", streams.last["action"]
      assert_equal "developer_message_#{message.id}", streams.last["target"]
    end
  end
end
