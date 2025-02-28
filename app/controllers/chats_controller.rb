class ChatsController < ApplicationController
  before_action :set_chat, only: [ :show, :destroy, :clear ]

  def index
    @chats = Current.user.chats.order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.where(internal: [ false, nil ]).order(created_at: :asc)
    @message = Message.new

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @chat = Current.user.chats.new(title: "New Chat", user: Current.user, family_id: Current.family.id)

    if @chat.save
      # Create initial system message with enhanced financial assistant context
      @chat.messages.create(
        content: "You are a helpful financial assistant for Maybe. You can answer questions about the user's finances including net worth, account balances, income, expenses, spending patterns, budgets, and financial goals. You have access to the user's financial data and can provide insights based on their transactions and accounts. Be conversational, helpful, and provide specific financial insights tailored to the user's question.",
        role: "system",
        internal: true
      )

      # Create user message if content is provided
      if params[:content].present?
        @user_message = @chat.messages.create(
          content: params[:content],
          role: "user",
          user: Current.user
        )
      end

      # Process AI response if user message was created
      if defined?(@user_message) && @user_message.persisted?
        ProcessAiResponseJob.perform_later(@chat.id, @user_message.id)
      end

      respond_to do |format|
        format.html { redirect_to root_path(chat_id: @chat.id) }
        format.turbo_stream { redirect_to root_path(chat_id: @chat.id, format: :html) }
      end
    else
      respond_to do |format|
        format.html { redirect_to chats_path, alert: "Failed to create chat" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("chat_form", partial: "chats/form", locals: { chat: @chat }) }
      end
    end
  end

  def destroy
    @chat.destroy
    redirect_to chats_path, notice: "Chat was successfully deleted"
  end

  def clear
    # Delete all non-system messages
    @chat.messages.where.not(role: "system").destroy_all

    # Re-add the system message if it doesn't exist
    unless @chat.messages.where(role: "system").exists?
      @chat.messages.create(
        content: "You are a helpful financial assistant for Maybe. You can answer questions about the user's finances including net worth, account balances, income, expenses, spending patterns, budgets, and financial goals. You have access to the user's financial data and can provide insights based on their transactions and accounts. Be conversational, helpful, and provide specific financial insights tailored to the user's question.",
        role: "system",
        internal: true
      )
    end

    respond_to do |format|
      format.html { redirect_to root_path(chat_id: @chat.id), notice: "Chat was successfully cleared" }
      format.turbo_stream
    end
  end

  private

    def set_chat
      @chat = Current.user.chats.find(params[:id])
    end
end
