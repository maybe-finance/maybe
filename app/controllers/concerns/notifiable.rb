module Notifiable
  extend ActiveSupport::Concern

  included do
    helper_method :render_flash_notifications
    helper_method :flash_notification_stream_items
  end

  private
    def render_flash_notifications
      notifications = flash.flat_map { |type, data| resolve_notifications(type, data) }.compact

      view_context.safe_join(
        notifications.map { |notification| view_context.render(**notification) }
      )
    end

    def flash_notification_stream_items
      items = flash.flat_map do |type, data|
        notifications = resolve_notifications(type, data)

        if type == "cta"
          notifications.map { |notification| turbo_stream.replace("cta", **notification) }
        else
          notifications.map { |notification| turbo_stream.append("notification-tray", **notification) }
        end
      end.compact

      # If rendering flash notifications via stream, we mark them as used to avoid
      # them being rendered again on the next page load
      flash.clear

      items
    end

    def resolve_cta(cta)
      case cta[:type]
      when "category_rule"
        { partial: "rules/category_rule_cta", locals: { cta: } }
      end
    end

    def resolve_notifications(type, data)
      case type
      when "alert"
        [ { partial: "shared/notifications/alert", locals: { message: data } } ]
      when "cta"
        [ resolve_cta(data) ]
      when "loading"
        [ { partial: "shared/notifications/loading", locals: { message: data } } ]
      when "notice"
        messages = Array(data)
        messages.map { |message| { partial: "shared/notifications/notice", locals: { message: message } } }
      else
        []
      end
    end
end
