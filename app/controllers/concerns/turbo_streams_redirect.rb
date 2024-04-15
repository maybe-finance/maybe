module TurboStreamsRedirect
  extend ActiveSupport::Concern

  def redirect_to(options = {}, response_options = {})
    turbo_frame = response_options.delete(:turbo_frame)
    turbo_action = response_options.delete(:turbo_action)
    location = url_for(options)

    if request.format.turbo_stream? && turbo_frame.present?
      alert, notice, flash_override = response_options.values_at(:alert, :notice, :flash)
      flash_to_merge = flash_override || {}
      flash_to_merge[:alert] = alert if alert.present?
      flash_to_merge[:notice] = notice if notice.present?
      flash.merge!(flash_to_merge)

      case Rack::Utils.status_code(response_options.fetch(:status, :created))
      when 300..399 then response_options[:status] = :created
      end

      render "turbo/streams/redirect", **response_options.with_defaults(
        locals: { location: location, turbo_frame: turbo_frame, turbo_action: turbo_action },
        location: location,
      )
    else
      super
    end
  end
end
