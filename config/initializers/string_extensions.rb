class String
  def unit
    CURRENCY_OPTIONS[self.to_sym][:unit]
  end

  def separator
    CURRENCY_OPTIONS[self.to_sym][:separator]
  end

  def precision
    CURRENCY_OPTIONS[self.to_sym][:precision]
  end
end
