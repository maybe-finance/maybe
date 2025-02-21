module Money::Formatting
  include ActiveSupport::NumberHelper

  def format(options = {})
    locale = options[:locale] || I18n.locale
    default_opts = format_options(locale)

    number_to_currency(amount, default_opts.merge(options))
  end
  alias_method :to_s, :format

  def format_options(locale = nil)
    local_option_overrides = locale_options(locale)

    {
      unit: currency.symbol,
      precision: currency.default_precision,
      delimiter: currency.delimiter,
      separator: currency.separator,
      format: currency.default_format
    }.merge(local_option_overrides)
  end

  private
    def locale_options(locale)
      case [ currency.iso_code, locale.to_sym ]
      when [ "EUR", :nl ], [ "EUR", :pt ]
        { delimiter: ".", separator: ",", format: "%u %n" }
      when [ "EUR", :en ], [ "EUR", :en_IE ]
        { delimiter: ",", separator: "." }
      else
        {}
      end
    end
end
