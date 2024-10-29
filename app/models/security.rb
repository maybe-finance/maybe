class Security < ApplicationRecord
  before_save :upcase_ticker

  has_many :trades, dependent: :nullify, class_name: "Account::Trade"
  has_many :prices, dependent: :destroy

  validates :ticker, presence: true
  validates :ticker, uniqueness: { scope: :exchange_mic, case_sensitive: false }

  def current_price
    @current_price ||= Security::Price.find_price(security: self, date: Date.current)
    return nil if @current_price.nil?
    Money.new(@current_price.price, @current_price.currency)
  end

  def to_combobox_display
    "#{ticker} - #{name} (#{exchange_acronym})"
  end


  private

    def upcase_ticker
      self.ticker = ticker.upcase
    end
end
