class MessagesController < ApplicationController
  before_action :set_chat

  def create
    @message = @chat.messages.create!(message_params.merge(role: "user"))

    redirect_to chat_path(@chat)
  end

  private
    def set_chat
      @chat = Current.user.chats.find(params[:chat_id])
    end

    def message_params
      params.require(:message).permit(:content)
    end
end
