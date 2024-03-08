module Filterable
    extend ActiveSupport::Concern

    included do
        before_action :set_period
    end

    private

      def set_period
        @period = Period.find_by_name(params[:period])
        if @period.nil?
          start_date = params[:start_date].presence&.to_date
          end_date = params[:end_date].presence&.to_date
          if start_date.is_a?(Date) && end_date.is_a?(Date) && start_date <= end_date
            @period = Period.new(name: "custom", date_range: start_date..end_date)
          else
            params[:period] = "last_30_days"
            @period = Period.find_by_name(params[:period])
          end
        end
      end
end
