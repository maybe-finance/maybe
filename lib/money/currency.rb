class Money::Currency
  include Comparable

  class UnknownCurrencyError < ArgumentError; end

  CURRENCIES_FILE_PATH = Rails.root.join("config", "currencies.yml")

  # Cached instances by iso code
  @@instances = {}

  class << self
    def new(object)
      iso_code = case object
      when String, Symbol
        object.to_s.downcase
      when Money::Currency
        object.iso_code.downcase
      else
        raise ArgumentError, "Invalid argument type"
      end

      @@instances[iso_code] ||= super(iso_code)
    end

    def all
      @all ||= YAML.safe_load(
        File.read(CURRENCIES_FILE_PATH),
        permitted_classes: [],
        permitted_symbols: [],
        aliases: true
      )
    end

    def all_instances
      all.values.map { |currency_data| new(currency_data["iso_code"]) }
    end

    def as_options
      all_instances.sort_by do |currency|
        [ currency.priority, currency.name ]
      end
    end

    def popular
      all.values.sort_by { |currency| currency["priority"] }.first(12).map { |currency_data| new(currency_data["iso_code"]) }
    end
  end

  attr_reader :name, :priority, :iso_code, :iso_numeric, :html_code,
              :symbol, :minor_unit, :minor_unit_conversion, :smallest_denomination,
              :separator, :delimiter, :default_format, :default_precision

  def initialize(iso_code)
    currency_data = self.class.all[iso_code]
    raise UnknownCurrencyError if currency_data.nil?

    @name = currency_data["name"]
    @priority = currency_data["priority"]
    @iso_code = currency_data["iso_code"]
    @iso_numeric = currency_data["iso_numeric"]
    @html_code = currency_data["html_code"]
    @symbol = currency_data["symbol"]
    @minor_unit = currency_data["minor_unit"]
    @minor_unit_conversion = currency_data["minor_unit_conversion"]
    @smallest_denomination = currency_data["smallest_denomination"]
    @separator = currency_data["separator"]
    @delimiter = currency_data["delimiter"]
    @default_format = currency_data["default_format"]
    @default_precision = currency_data["default_precision"]
  end

  def step
    (1.0/10**default_precision)
  end

  def <=>(other)
    return nil unless other.is_a?(Money::Currency)
    @iso_code <=> other.iso_code
  end
end
