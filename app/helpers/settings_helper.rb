module SettingsHelper
  def next_setting(title, path)
    render partial: "settings/nav_link_large", locals: { path: path, direction: "next", title: title }
  end

  def previous_setting(title, path)
    render partial: "settings/nav_link_large", locals: { path: path, direction: "previous", title: title }
  end
end
