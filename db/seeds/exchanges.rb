# Load exchanges from YAML configuration
exchanges_config = YAML.safe_load(
  File.read(Rails.root.join('config', 'exchanges.yml')),
  permitted_classes: [],
  permitted_symbols: [],
  aliases: true
)

exchanges_config.each do |exchange|
  next unless exchange['mic'].present? # Skip any invalid entries

  StockExchange.find_or_create_by!(mic: exchange['mic']) do |ex|
    ex.name = exchange['name']
    ex.acronym = exchange['acronym']
    ex.country = exchange['country']
    ex.country_code = exchange['country_code']
    ex.city = exchange['city']
    ex.website = exchange['website']

    # Timezone details
    if exchange['timezone']
      ex.timezone_name = exchange['timezone']['timezone']
      ex.timezone_abbr = exchange['timezone']['abbr']
      ex.timezone_abbr_dst = exchange['timezone']['abbr_dst']
    end

    # Currency details
    if exchange['currency']
      ex.currency_code = exchange['currency']['code']
      ex.currency_symbol = exchange['currency']['symbol']
      ex.currency_name = exchange['currency']['name']
    end
  end
end

puts "Created #{StockExchange.count} stock exchanges"
