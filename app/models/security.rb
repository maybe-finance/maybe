class Security < ApplicationRecord
  before_save :upcase_ticker

  has_many :trades, dependent: :nullify, class_name: "Account::Trade"
  has_many :prices, dependent: :destroy

  validates :ticker, presence: true
  validates :ticker, uniqueness: { scope: :exchange_mic, case_sensitive: false }

  scope :search, ->(query) {
    return none if query.blank? || query.length < 2

    # Clean and normalize the search terms
    sanitized_query = query.split.map do |term|
      cleaned_term = term.gsub(/[^a-zA-Z0-9]/, " ").strip
      next if cleaned_term.blank?
      cleaned_term
    end.compact.join(" | ")

    return none if sanitized_query.blank?

    sanitized_query = ActiveRecord::Base.connection.quote(sanitized_query)

    where("search_vector @@ to_tsquery('simple', #{sanitized_query}) AND exchange_mic IS NOT NULL")
      .select("securities.*, ts_rank_cd(search_vector, to_tsquery('simple', #{sanitized_query})) AS rank")
      .reorder("rank DESC")
  }

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
