class Security < ApplicationRecord
  include Provided

  before_save :upcase_ticker

  has_many :trades, dependent: :nullify, class_name: "Trade"
  has_many :prices, dependent: :destroy

  validates :ticker, presence: true
  validates :ticker, uniqueness: { scope: :exchange_operating_mic, case_sensitive: false }

  def current_price
    @current_price ||= find_or_fetch_price
    return nil if @current_price.nil?
    Money.new(@current_price.price, @current_price.currency)
  end

  def to_combobox_option
    SynthComboboxOption.new(
      symbol: ticker,
      name: name,
      logo_url: logo_url,
      exchange_operating_mic: exchange_operating_mic,
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
