class MessagesController < ApplicationController
  before_action :set_chat
  before_action :ensure_ai_enabled

  def create
    @message = @chat.messages.new(message_params)
    @message.user = Current.user
    @message.role = "user"

    if @message.save
      respond_to do |format|
        format.html { redirect_to root_path(chat_id: @chat.id) }
        format.turbo_stream
      end

      # Process AI response in background
      ProcessAiResponseJob.perform_later(@chat.id, @message.id)
    else
      respond_to do |format|
        format.html { redirect_to root_path(chat_id: @chat.id), alert: "Failed to send message" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { chat: @chat, message: @message }) }
      end
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
