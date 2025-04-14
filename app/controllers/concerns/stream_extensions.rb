module StreamExtensions
  extend ActiveSupport::Concern

  def stream_redirect_to(path, notice: nil, alert: nil)
    custom_stream_redirect(path, notice: notice, alert: alert)
  end

  def stream_redirect_back_or_to(path, notice: nil, alert: nil)
    custom_stream_redirect(path, redirect_back: true, notice: notice, alert: alert)
  end

  private
    def custom_stream_redirect(path, redirect_back: false, notice: nil, alert: nil)
      flash[:notice] = notice if notice.present?
      flash[:alert] = alert if alert.present?

      redirect_target_url = redirect_back ? request.referer : path
      render turbo_stream: turbo_stream.action(:redirect, redirect_target_url)
    end
end
