class Security::SynthComboboxOption
  include ActiveModel::Model
  include Providable

  attr_accessor :symbol, :name, :logo_url, :exchange_acronym, :exchange_mic

  class << self
    def find_in_synth(query)
      security_prices_provider.search_securities(query:, dataset: "limited", country_code: Current.family.country).securities.map { |attrs| new(**attrs) }
    end
  end

  def id
    "#{symbol} (#{exchange_mic})" # submitted by combobox as value
  end

  def to_combobox_display
    "#{symbol} - #{name} (#{exchange_acronym})" # shown in combobox input when selected
  end
end
