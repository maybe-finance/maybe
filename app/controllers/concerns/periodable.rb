module Periodable
  extend ActiveSupport::Concern

  included do
    before_action :set_period
  end

  private
    def set_period
      @period = Period.from_key(params[:period] || Current.user&.default_period)
    rescue Period::InvalidKeyError
      @period = Period.last_30_days
    end
end
