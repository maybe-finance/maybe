class Security::SynthComboboxOption
  include ActiveModel::Model

  attr_accessor :symbol, :name, :logo_url, :exchange_acronym, :exchange_mic, :exchange_country_code

  def id
    "#{symbol}|#{exchange_mic}|#{exchange_acronym}|#{exchange_country_code}" # submitted by combobox as value
  end

  def to_combobox_display
    "#{symbol} - #{name} (#{exchange_acronym})" # shown in combobox input when selected
  end
end
