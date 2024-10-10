class Security < ApplicationRecord
  before_save :upcase_ticker

  has_many :trades, dependent: :nullify, class_name: "Account::Trade"

  validates :ticker, presence: true, uniqueness: { case_sensitive: false }

  def current_price
    @current_price ||= Security::Price.find_price(ticker:, date: Date.current)
    return nil if @current_price.nil?
    Money.new(@current_price.price, @current_price.currency)
  end

  private

    def upcase_ticker
      self.ticker = ticker.upcase
    end
end
