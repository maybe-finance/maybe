class Security < ApplicationRecord
  include Providable

  before_save :upcase_ticker

  has_many :trades, dependent: :nullify, class_name: "Account::Trade"
  has_many :prices, dependent: :destroy

  validates :ticker, presence: true
  validates :ticker, uniqueness: { scope: :exchange_operating_mic, case_sensitive: false }

  class << self
    def provider
      security_prices_provider
    end

    def search(query)
      security_prices_provider.search_securities(
        query: query[:search],
        dataset: "limited",
        country_code: query[:country],
        exchange_operating_mic: query[:exchange_operating_mic]
      ).securities.map { |attrs| new(**attrs) }
    end
  end

  def current_price
    @current_price ||= Security::Price.find_price(security: self, date: Date.current)
    return nil if @current_price.nil?
    Money.new(@current_price.price, @current_price.currency)
  end

  def to_combobox_option
    SynthComboboxOption.new(
      symbol: ticker,
      name: name,
      logo_url: logo_url,
      exchange_acronym: exchange_acronym,
      exchange_operating_mic: exchange_operating_mic,
      exchange_country_code: country_code
    )
  end

  def has_prices?
    exchange_operating_mic.present?
  end

  private

    def upcase_ticker
      self.ticker = ticker.upcase
    end
end
