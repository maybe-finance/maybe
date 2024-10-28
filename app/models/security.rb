class Security < ApplicationRecord
  before_save :upcase_ticker

  has_many :trades, dependent: :nullify, class_name: "Account::Trade"

  validates :ticker, presence: true
  validates :ticker, uniqueness: { scope: :exchange_mic, case_sensitive: false }

  scope :search, ->(query) {
    return nil if query.blank? || query.length < 2
    sanitized_query = query.split.map { |term| "#{term}:*" }.join(" & ")
    select("securities.*, ts_rank_cd(search_vector, to_tsquery('simple', $1)) AS rank")
      .where("search_vector @@ to_tsquery('simple', :q)", q: sanitized_query)
      .reorder("rank DESC")
  }

  def current_price
    @current_price ||= Security::Price.find_price(ticker:, date: Date.current)
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
