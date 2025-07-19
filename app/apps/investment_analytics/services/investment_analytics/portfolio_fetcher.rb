# app/apps/investment_analytics/services/investment_analytics/portfolio_fetcher.rb

module InvestmentAnalytics
  class PortfolioFetcher
    def initialize(account)
      @account = account
    end

    def fetch
      holdings_data = @account.holdings.includes(:security).map do |holding|
        # Fetch latest price for the security
        latest_price = holding.security.prices.order(date: :desc).first
        
        # Convert holding value to account's currency
        # Assuming Money gem is configured and ExchangeRate is available
        # This part needs careful implementation based on Maybe's actual models
        # For now, a simplified conversion
        
        # Use InvestmentAnalytics::ExchangeRateConverter for currency conversion
        converted_price_money = if latest_price
                                  InvestmentAnalytics::ExchangeRateConverter.convert(
                                    Money.from_amount(latest_price.amount, latest_price.currency),
                                    @account.currency
                                  )
                                else
                                  nil
                                end
        converted_price_amount = converted_price_money&.amount

        current_value = converted_price_amount.to_d * holding.shares.to_d if converted_price_amount
        
        {
          id: holding.id,
          security_id: holding.security.id,
          symbol: holding.security.ticker,
          name: holding.security.name,
          shares: holding.shares,
          cost_basis: holding.cost_basis, # Assuming cost_basis is in account currency
          current_price: converted_price_amount,
          current_value: current_value,
          currency: @account.currency, # Assuming holding is valued in account currency
          sector: holding.security.sector, # Assuming security has a sector attribute
          # Add more relevant data points as needed
        }
      end.compact

      # Calculate total portfolio value
      total_value = holdings_data.sum { |h| h[:current_value] || 0 }

      {
        account_id: @account.id,
        account_name: @account.name,
        total_value: total_value,
        holdings: holdings_data
      }
    end
  end
end
