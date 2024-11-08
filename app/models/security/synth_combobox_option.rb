class Security::SynthComboboxOption
  include ActiveModel::Model
  include Providable

  attr_accessor :symbol, :name, :logo_url, :exchange_acronym, :exchange_mic, :exchange_country_code

  class << self
    def find_in_synth(query)
      country = Current.family.country
      country = "#{country},US" unless country == "US"

      security_prices_provider.search_securities(
        query:,
        dataset: "limited",
        country_code: country
      ).securities.map { |attrs| new(**attrs) }
    end
  end

  def id
    "#{symbol}|#{exchange_mic}|#{exchange_acronym}|#{exchange_country_code}" # submitted by combobox as value
  end

  def to_combobox_display
    "#{symbol} - #{name} (#{exchange_acronym})" # shown in combobox input when selected
  end
end
