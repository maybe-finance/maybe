# frozen_string_literal: true

class Api::V1::ChatsController < Api::V1::BaseController
  include Pagy::Backend
  before_action :require_ai_enabled
  before_action :ensure_read_scope, only: [ :index, :show ]
  before_action :ensure_write_scope, only: [ :create, :update, :destroy ]
  before_action :set_chat, only: [ :show, :update, :destroy ]

  def index
    @pagy, @chats = pagy(Current.user.chats.ordered, items: 20)
  end

  def show
    return unless @chat
    @pagy, @messages = pagy(@chat.messages.ordered, items: 50)
  end

  def create
    @chat = Current.user.chats.build(title: chat_params[:title])

    if @chat.save
      if chat_params[:message].present?
        @message = @chat.messages.build(
          content: chat_params[:message],
          type: "UserMessage",
          ai_model: chat_params[:model] || "gpt-4"
        )

        if @message.save
          AssistantResponseJob.perform_later(@message)
          render :show, status: :created
        else
          @chat.destroy
          render json: { error: "Failed to create initial message", details: @message.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render :show, status: :created
      end
    else
      render json: { error: "Failed to create chat", details: @chat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    return unless @chat

    if @chat.update(update_chat_params)
      render :show
    else
      render json: { error: "Failed to update chat", details: @chat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return unless @chat
    @chat.destroy
    head :no_content
  end

  private

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def set_chat
      @chat = Current.user.chats.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Chat not found" }, status: :not_found
    end

    def chat_params
      params.permit(:title, :message, :model)
    end

    def update_chat_params
      params.permit(:title)
    end
end
