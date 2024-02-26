class String
  def unit
    CURRENCY_OPTIONS[self.to_sym][:unit]
  end

  def separator
    CURRENCY_OPTIONS[self.to_sym][:separator]
  end
end
