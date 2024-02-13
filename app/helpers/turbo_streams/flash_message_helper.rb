module TurboStreams::FlashMessageHelper
  def flash_message(flash)
    messages = flash.map do |type, message|
      turbo_stream_action_tag(:flash_message, type: type, message: message)
    end.join.html_safe
    flash.clear
    messages
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreams::FlashMessageHelper)
