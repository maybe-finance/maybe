# Captures the most recent holding quantities for each security in an account's portfolio.
# Returns a portfolio hash compatible with the reverse calculator's format.
class Holding::PortfolioSnapshot
  attr_reader :account

  def initialize(account)
    @account = account
  end

  # Returns a hash of {security_id => qty} representing today's starting portfolio.
  # Includes all securities from trades (with 0 qty if no holdings exist).
  def to_h
    @portfolio ||= build_portfolio
  end

  private
    def build_portfolio
      # Start with all securities from trades initialized to 0
      portfolio = account.trades
        .pluck(:security_id)
        .uniq
        .each_with_object({}) { |security_id, hash| hash[security_id] = 0 }

      # Get the most recent holding for each security and update quantities
      account.holdings
        .select("DISTINCT ON (security_id) security_id, qty")
        .order(:security_id, date: :desc)
        .each { |holding| portfolio[holding.security_id] = holding.qty }

      portfolio
    end
end
