class Numeric
  def cents(precision: 2)
    return "" unless precision.positive?

    cents = self.to_s.split(".")[1]
    cents = "" unless cents.to_i.positive?

    zero_padded_cents = cents.ljust(precision, "0")
    zero_padded_cents[0..precision - 1]
  end
end
