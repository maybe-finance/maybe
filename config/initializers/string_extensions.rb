class String
  def currency_unit
    CURRENCY_OPTIONS[self.to_sym][:unit]
  end

  def currency_separator
    CURRENCY_OPTIONS[self.to_sym][:separator]
  end

  def cents_part(precision: 2)
    cents = self.split(".")[1]
    cents = "" unless cents.to_i.positive?

    zero_padded_cents = cents.ljust(precision, "0")
    zero_padded_cents[0..precision - 1]
  end
end
