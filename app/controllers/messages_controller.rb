class MessagesController < ApplicationController
  guard_feature unless: -> { Current.user.ai_enabled? }

  before_action :set_chat

  def create
    @message = UserMessage.create!(
      chat: @chat,
      content: message_params[:content],
      ai_model: message_params[:ai_model]
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
      params.require(:message).permit(:content, :ai_model)
    end
end
