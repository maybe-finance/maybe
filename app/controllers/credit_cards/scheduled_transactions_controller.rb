module CreditCards
  class ScheduledTransactionsController < ApplicationController
    before_action :set_credit_card
    before_action :set_scheduled_transaction, only: [:edit, :update, :destroy]
    before_action :load_form_dependencies, only: [:new, :create, :edit, :update]

    def new
      @scheduled_transaction = @credit_card.scheduled_transactions.new(currency: @credit_card.currency)
    end

    def create
      @scheduled_transaction = @credit_card.scheduled_transactions.new(scheduled_transaction_params)
      if @scheduled_transaction.save
        flash.now[:notice] = 'Scheduled transaction was successfully created.'
        respond_to do |format|
          format.html { redirect_to credit_card_path(@credit_card) }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("scheduled_transactions_for_#{@credit_card.id}", partial: "credit_cards/scheduled_transactions/scheduled_transaction", locals: { credit_card: @credit_card, scheduled_transaction: @scheduled_transaction }),
              turbo_stream.replace("new_scheduled_transaction_for_#{@credit_card.id}", ""), # Clear the form
              *flash_notification_stream_items # Assuming you have this helper for flash messages
            ]
          end
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @scheduled_transaction.update(scheduled_transaction_params)
        flash.now[:notice] = 'Scheduled transaction was successfully updated.'
        respond_to do |format|
          format.html { redirect_to credit_card_path(@credit_card) }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@scheduled_transaction, partial: "credit_cards/scheduled_transactions/scheduled_transaction", locals: { credit_card: @credit_card, scheduled_transaction: @scheduled_transaction }),
              *flash_notification_stream_items
            ]
          end
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @scheduled_transaction.destroy
      flash.now[:notice] = 'Scheduled transaction was successfully destroyed.'
      respond_to do |format|
        format.html { redirect_to credit_card_path(@credit_card) }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@scheduled_transaction),
            *flash_notification_stream_items
          ]
        end
      end
    end

    private

    def set_credit_card
      # Assuming Account model is used for credit cards
      @credit_card = Current.family.accounts.find(params[:credit_card_id])
      # You might want to add an authorization check here to ensure the account is indeed a credit card
      # or that the user is allowed to manage scheduled transactions for it.
      # e.g., redirect_to root_path, alert: "Not a valid credit card account" unless @credit_card.accountable_type == "CreditCard"
    end

    def set_scheduled_transaction
      @scheduled_transaction = @credit_card.scheduled_transactions.find(params[:id])
    end

    def load_form_dependencies
      @categories = Current.family.categories.expenses.alphabetically
      @merchants = Current.family.merchants.alphabetically
    end

    def scheduled_transaction_params
      params.require(:scheduled_transaction).permit(
        :description,
        :amount,
        :currency,
        :frequency,
        :installments,
        # :current_installment, # Typically not directly set by user
        :next_occurrence_date,
        :end_date,
        :category_id,
        :merchant_id
      ).tap do |p|
        # Ensure currency is set if not provided, defaulting to account's currency
        p[:currency] ||= @credit_card.currency
      end
    end
  end
end
