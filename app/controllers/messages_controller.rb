class MessagesController < ApplicationController
  guard_feature unless: -> { Current.user.ai_enabled? }

  before_action :set_chat

  def create
    @message = @chat.messages.user.create!(
      content: message_params[:content]
    )

    respond_to do |format|
      format.html { redirect_to chat_path(@chat) }
      format.turbo_stream
    end
  end

  private
    def set_chat
      @chat = Current.user.chats.find(params[:chat_id])
    end

    def message_params
      params.require(:message).permit(:content)
    end
end
