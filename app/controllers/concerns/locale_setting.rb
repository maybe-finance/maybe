module LocaleSetting
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    locale = extract_locale_from_cookie
    I18n.locale = I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale
  end

  def extract_locale_from_cookie
    cookies[:locale]
  end
end
