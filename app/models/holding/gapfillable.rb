module Holding::Gapfillable
  extend ActiveSupport::Concern

  class_methods do
    def gapfill(holdings)
      filled_holdings = []

      holdings.group_by { |h| h.security_id }.each do |security_id, security_holdings|
        next if security_holdings.empty?

        sorted = security_holdings.sort_by(&:date)
        previous_holding = sorted.first

        sorted.first.date.upto(Date.current) do |date|
          holding = security_holdings.find { |h| h.date == date }

          if holding
            filled_holdings << holding
            previous_holding = holding
          else
            # Create a new holding based on the previous day's data
            filled_holdings << Holding.new(
              account: previous_holding.account,
              security: previous_holding.security,
              date: date,
              qty: previous_holding.qty,
              price: previous_holding.price,
              currency: previous_holding.currency,
              amount: previous_holding.amount
            )
          end
        end
      end

      filled_holdings
    end
  end
end
