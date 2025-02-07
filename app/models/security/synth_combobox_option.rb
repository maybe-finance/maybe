class Security::SynthComboboxOption
  include ActiveModel::Model

  attr_accessor :symbol, :name, :logo_url, :exchange_acronym, :exchange_mic, :exchange_country_code, :exchange_operating_mic

  def id
    "#{symbol}|#{exchange_mic}|#{exchange_acronym}|#{exchange_country_code}|#{exchange_operating_mic}" # submitted by combobox as value
  end

  def to_combobox_display
    display_code = exchange_acronym.presence || exchange_operating_mic
    "#{symbol} - #{name} (#{display_code})" # shown in combobox input when selected
  end
end
