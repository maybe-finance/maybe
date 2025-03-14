class MessagesController < ApplicationController
  before_action :set_chat
  before_action :ensure_ai_enabled

  def create
    @message = @chat.messages.create!(message_params)

    # TODO: Enable again
    # ProcessAiResponseJob.perform_later(@message)

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

    def ensure_ai_enabled
      unless Current.user.ai_enabled?
        redirect_to root_path, alert: "AI chat is not enabled. Please enable it in your settings."
      end
    end
end
