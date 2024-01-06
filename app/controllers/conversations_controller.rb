class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = current_user.conversations.order(updated_at: :desc)
  end

  def show
    @conversation = current_user.conversations.find_by(id: params[:id])
  end

  def new
    # Create a new conversation and redirect to it
    @conversation = Conversation.new
    @conversation.user = current_user
    @conversation.title = "New Conversation"
    @conversation.save

    redirect_to @conversation
  end

  def update
    # Conversation is already created, so find it based on params id and current_user
    @conversation = Conversation.find_by(id: params[:id], user: current_user)

    if params[:conversation].present?
      @message = @conversation.messages.new
      @message.content = params[:conversation][:content]
      @message.user = current_user
      @message.role = "user"

      @conversation.save

      # Stub reply from bot
      reply = @conversation.messages.new
      reply.content = "..."
      reply.user = nil
      reply.role = "assistant"
      reply.save

      AskQuestionJob.perform(@conversation.id, reply.id)

      #conversation.broadcast_append_to "conversation_area", partial: "conversations/message", locals: { message: reply }, target: "conversation_area_#{conversation.id}"

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("conversation_area_#{@conversation.id}", partial: 'conversations/message', locals: { message: @message }),
            turbo_stream.append("conversation_area_#{@conversation.id}", partial: 'conversations/message', locals: { message: reply }),
          ]
        end
        format.html { redirect_to @conversation }
      end
    end
  end

private

  def conversation_params
    params.require(:conversation).permit(:conversation_params)
  end
end
