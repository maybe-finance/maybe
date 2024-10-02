module Money::Formatting
  # Fallback formatting.  For advanced formatting, use Rails number_to_currency helper.
  def format
    whole_part, fractional_part = sprintf("%.#{currency.default_precision}f", amount).split(".")
    whole_with_delimiters = whole_part.chars.to_a.reverse.each_slice(3).map(&:join).join(currency.delimiter).reverse
    formatted_amount = "#{whole_with_delimiters}#{currency.separator}#{fractional_part}"

    currency.default_format.gsub("%n", formatted_amount).gsub("%u", currency.symbol)
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
