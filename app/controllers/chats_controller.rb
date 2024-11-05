class ChatsController < ApplicationController
  def new
    @chat = Current.user.chats.create

    redirect_to chat_path(@chat)
  end

  def show
    @chat = Current.user.chats.find(params[:id])
  end

  def update
    @chat = Current.user.chats.find(params[:id])

    @message = @chat.messages.create(user: Current.user, content: params[:message][:content], role: "user")

    ChatJob.perform_later(@message)
  end
end
