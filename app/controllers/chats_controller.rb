class ChatsController < ApplicationController
  def index
    Current.user.update!(current_chat: nil)
    @chats = Current.user.chats.ordered
  end

  def create
    @chat = Current.user.chats.create_with_defaults!

    redirect_to chat_path(@chat)
  end

  def show
    @chat = Current.user.chats.find(params[:id])
    Current.user.update!(current_chat: @chat)
  end
end
