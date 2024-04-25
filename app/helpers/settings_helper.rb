module SettingsHelper
  def next_setting(title, path)
    render partial: "settings/nav_link_large", locals: { path: path, direction: "next", title: title }
  end

  def previous_setting(title, path)
    render partial: "settings/nav_link_large", locals: { path: path, direction: "previous", title: title }
  end

  def settings_section(title:, subtitle: nil, &block)
    content = capture(&block)
    render partial: "settings/section", locals: { title: title, subtitle: subtitle, content: content }
  end
end
