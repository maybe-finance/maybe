module SettingsHelper
  SETTINGS_ORDER = [
    { name: I18n.t("settings.settings_nav.profile_label"), path: :settings_profile_path },
    { name: I18n.t("settings.settings_nav.preferences_label"), path: :settings_preferences_path },
    { name: I18n.t("settings.settings_nav.security_label"), path: :settings_security_path },
    { name: I18n.t("settings.settings_nav.self_hosting_label"), path: :settings_hosting_path, condition: :self_hosted? },
    { name: I18n.t("settings.settings_nav.billing_label"), path: :settings_billing_path, condition: :not_self_hosted? },
    { name: I18n.t("settings.settings_nav.accounts_label"), path: :accounts_path },
    { name: I18n.t("settings.settings_nav.imports_label"), path: :imports_path },
    { name: I18n.t("settings.settings_nav.tags_label"), path: :tags_path },
    { name: I18n.t("settings.settings_nav.categories_label"), path: :categories_path },
    { name: "Rules", path: :rules_path },
    { name: I18n.t("settings.settings_nav.merchants_label"), path: :family_merchants_path },
    { name: I18n.t("settings.settings_nav.whats_new_label"), path: :changelog_path },
    { name: I18n.t("settings.settings_nav.feedback_label"), path: :feedback_path }
  ]

  def adjacent_setting(current_path, offset)
    visible_settings = SETTINGS_ORDER.select { |setting| setting[:condition].nil? || send(setting[:condition]) }
    current_index = visible_settings.index { |setting| send(setting[:path]) == current_path }
    return nil unless current_index

    adjacent_index = current_index + offset
    return nil if adjacent_index < 0 || adjacent_index >= visible_settings.size

    adjacent = visible_settings[adjacent_index]

    render partial: "settings/settings_nav_link_large", locals: {
      path: send(adjacent[:path]),
      direction: offset > 0 ? "next" : "previous",
      title: adjacent[:name]
    }
  end

  def settings_section(title:, subtitle: nil, &block)
    content = capture(&block)
    render partial: "settings/section", locals: { title: title, subtitle: subtitle, content: content }
  end

  def settings_nav_footer
    previous_setting = adjacent_setting(request.path, -1)
    next_setting = adjacent_setting(request.path, 1)

    content_tag :div, class: "hidden md:flex flex-row justify-between gap-4" do
      concat(previous_setting)
      concat(next_setting)
    end
  end

  def settings_nav_footer_mobile
    previous_setting = adjacent_setting(request.path, -1)
    next_setting = adjacent_setting(request.path, 1)

    content_tag :div, class: "md:hidden flex flex-col gap-4" do
      concat(previous_setting)
      concat(next_setting)
    end
  end

  private
    def not_self_hosted?
      !self_hosted?
    end
end
