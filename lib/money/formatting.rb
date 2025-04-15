module Money::Formatting
  include ActiveSupport::NumberHelper

  def format(options = {})
    locale = options[:locale] || I18n.locale
    default_opts = format_options(locale)

    if options[:abbreviate]
      format_abbreviated(default_opts.merge(options))
    else
      number_to_currency(amount, default_opts.merge(options))
    end
  end
  alias_method :to_s, :format

  def format_options(locale = nil)
    local_option_overrides = locale_options(locale)

    {
      unit: get_symbol,
      precision: currency.default_precision,
      delimiter: currency.delimiter,
      separator: currency.separator,
      format: currency.default_format
    }.merge(local_option_overrides)
  end

  private
    def format_abbreviated(options)
      threshold = options[:abbreviate_threshold] || 1000
      abs_amount = amount.abs

      return number_to_currency(amount, options) if abs_amount < threshold

      suffixes = options[:unit_suffixes]

      if abs_amount >= 1_000_000_000
        unit_suffix = suffixes[:billion]
        value = abs_amount / 1_000_000_000.0
      elsif abs_amount >= 1_000_000
        unit_suffix = suffixes[:million]
        value = abs_amount / 1_000_000.0
      else
        unit_suffix = suffixes[:thousand]
        value = abs_amount / 1000.0
      end

      # Always use period as decimal separator for abbreviations
      abbrev_options = options.merge(precision: 1, separator: ".")
      value_formatted = number_to_rounded(value, abbrev_options)
      abbreviated_num = "#{value_formatted}#{unit_suffix}"

      if options[:format].to_s.include?("%u %n")
        formatted = "#{options[:unit]} #{abbreviated_num}"
      else
        formatted = "#{options[:unit]}#{abbreviated_num}"
      end

      amount.negative? ? "-#{formatted}" : formatted
    end

    def get_symbol
      if currency.symbol == "$" && currency.iso_code != "USD"
        [ currency.iso_code.first(2), currency.symbol ].join
      else
        currency.symbol
      end
    end

    def locale_options(locale)
      case [ currency.iso_code, locale.to_sym ]
      when [ "EUR", :nl ], [ "EUR", :pt ]
        {
          delimiter: ".",
          separator: ",",
          format: "%u %n",
          unit_suffixes: { thousand: "K", million: "M", billion: "B" }
        }
      when [ "EUR", :en ], [ "EUR", :en_IE ]
        {
          delimiter: ",",
          separator: ".",
          unit_suffixes: { thousand: "K", million: "M", billion: "B" }
        }
      else
        { unit_suffixes: { thousand: "K", million: "M", billion: "B" } }
      end
    end
end
