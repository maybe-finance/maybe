class ChatsController < ApplicationController
  def new
    @chat = Current.user.chats.new
  end

  def create
    @chat = Current.user.chats.create
    @message = @chat.messages.create(
      user: Current.user,
      content: chat_params[:content],
      role: "user"
    )

    # Stub reply from bot
    reply = @chat.messages.create(
      content: "...",
      user: nil,
      role: "assistant"
    )

    ChatJob.perform_later(@chat.id, reply.id)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.update("new_chat", partial: "chats/chat", locals: { chat: @chat })
      }
    end
  end

  def show
    @chat = Current.user.chats.find(params[:id])
  end

  def update
    @chat = Current.user.chats.find(params[:id])
    @message = @chat.messages.create(
      user: Current.user,
      content: params[:message][:content],
      role: "user"
    )

    # Stub reply from bot
    reply = @chat.messages.create(
      content: "...",
      user: nil,
      role: "assistant"
    )

    ChatJob.perform_later(@chat.id, reply.id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("chat_messages", partial: "chats/message", locals: { message: @message }),
          turbo_stream.append("chat_messages", partial: "chats/message", locals: { message: reply }),
          turbo_stream.replace("chat_form", partial: "chats/form", locals: { chat: @chat })
        ]
      end
    end
  end

  private

    def chat_params
      params.require(:chat).permit(:content)
    end
end
