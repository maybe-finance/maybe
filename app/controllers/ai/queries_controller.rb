module Ai
  class QueriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_financial_assistant

    # Allow JSON requests
    protect_from_forgery with: :null_session, only: [ :create ], if: -> { request.format.json? }

    def create
      query = params[:query]

      respond_to do |format|
        if query.present?
          # Process the query using our financial assistant
          response = @financial_assistant.query(query)

          format.html { redirect_to root_path, notice: "Query processed successfully." }
          format.json { render json: { response: response, success: true } }
        else
          format.html { redirect_to root_path, alert: "Please provide a query." }
          format.json { render json: { response: "Please provide a query.", success: false }, status: :unprocessable_entity }
        end
      end
    end

    private

      def set_financial_assistant
        @financial_assistant = Ai::FinancialAssistant.new(Current.user.family)
      end
  end
end
