class ChatsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_chat, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_ai_enabled, only: [ :edit, :update, :create, :show ]

  def index
    @chat = nil # override application_controller default behavior of setting @chat to last viewed chat
    @chats = Current.user.chats.order(created_at: :desc)
  end

  def show
    set_last_viewed_chat(@chat)
    @messages = @chat.messages.conversation.ordered
    @message = Message.new

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @chat = Current.user.chats.new(title: "New chat #{Time.current.strftime("%Y-%m-%d %H:%M")}")
  end

  def create
    @chat = Current.user.chats.new(chat_params.merge(title: "New Chat"))

    if @chat.save
      set_last_viewed_chat(@chat)

      # Create initial system message with enhanced financial assistant context
      @chat.messages.create(
        content: "You are a helpful financial assistant for Maybe. You can answer questions about the user's finances including net worth, account balances, income, expenses, spending patterns, budgets, and financial goals. You have access to the user's financial data and can provide insights based on their transactions and accounts. Be conversational, helpful, and provide specific financial insights tailored to the user's question.",
        role: "developer",
      )

      # Create user message if content is provided
      if params[:content].present?
        @user_message = @chat.messages.create(
          content: params[:content],
          role: "user",
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

  def edit
  end

  def update
    @chat.update!(chat_params)

    respond_to do |format|
      format.html { redirect_back_or_to chat_path(@chat), notice: "Chat updated" }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@chat, :title), partial: "chats/chat_title", locals: { chat: @chat }) }
    end
  end

  def destroy
    @chat.destroy
    clear_last_viewed_chat
    redirect_to chats_path, notice: "Chat was successfully deleted"
  end

  private
    def set_chat
      @chat = Current.user.chats.find(params[:id])
    end

    def set_last_viewed_chat(chat)
      Current.user.update!(last_viewed_chat: chat)
    end

    def clear_last_viewed_chat
      Current.user.update!(last_viewed_chat: nil)
    end

    def chat_params
      params.require(:chat).permit(:title, :content)
    end

    def ensure_ai_enabled
      unless Current.user.ai_enabled?
        redirect_to root_path, alert: "AI chat is not enabled. Please enable it in your settings."
      end
    end
end
