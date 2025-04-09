module StreamExtensions
  extend ActiveSupport::Concern

  def stream_redirect_back_or_to(path, options = {})
    flash[:notice] = options[:notice] if options[:notice].present?
    flash[:alert] = options[:alert] if options[:alert].present?

    redirect_target_url = request.referer || path
    render turbo_stream: turbo_stream.action(:redirect, redirect_target_url)
  end
end
