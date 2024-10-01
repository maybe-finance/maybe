module Localize
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private
    def switch_locale(&action)
      locale = Current.family.try(:locale) || I18n.default_locale
      I18n.with_locale(locale, &action)
    end
end
