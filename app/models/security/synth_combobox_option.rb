class Security::SynthComboboxOption
  include ActiveModel::Model

  attr_accessor :symbol, :name, :logo_url, :exchange_operating_mic, :country_code

  def id
    "#{symbol}|#{exchange_operating_mic}" # submitted by combobox as value
  end

  def to_combobox_display
    "#{symbol} - #{name} (#{exchange_operating_mic})" # shown in combobox input when selected
  end
end
