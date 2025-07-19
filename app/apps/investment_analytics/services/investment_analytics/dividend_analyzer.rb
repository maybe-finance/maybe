# app/apps/investment_analytics/services/investment_analytics/dividend_analyzer.rb

require_relative './exchange_rate_converter'

module InvestmentAnalytics
  class DividendAnalyzer
    def initialize(portfolio_data, account_currency)
      @portfolio_data = portfolio_data
      @account_currency = account_currency
      @fmp_provider = Provider::Registry.get_provider(:fmp)
      raise "FMP Provider not registered" unless @fmp_provider
    end

    def analyze
      dividend_forecast = []
      total_portfolio_dividend_yield = Money.from_amount(0, @account_currency)
      total_portfolio_value = @portfolio_data[:total_value]

      @portfolio_data[:holdings].each do |holding|
        symbol = holding[:symbol]
        shares = holding[:shares]
        current_value = holding[:current_value]

        next unless symbol && shares && current_value && current_value.positive?

        begin
          historical_dividends = @fmp_provider.historical_dividends(symbol)
          
          if historical_dividends.present?
            # Simple approach: calculate TTM (Trailing Twelve Months) dividend
            # In a real app, you'd want more sophisticated logic for forecasting
            ttm_dividends = historical_dividends.select do |div|
              div['date'] && Date.parse(div['date']) >= 1.year.ago
            end.sum { |div| div['dividend'].to_d }

            # Convert TTM dividend to account currency
            ttm_dividends_money = Money.from_amount(ttm_dividends, holding[:currency])
            converted_ttm_dividends = InvestmentAnalytics::ExchangeRateConverter.convert(
                                        ttm_dividends_money,
                                        @account_currency
                                      )

            annual_dividend_income = converted_ttm_dividends * shares
            dividend_yield = (annual_dividend_income.to_d / current_value.to_d) * 100 if current_value.positive?

            dividend_forecast << {
              symbol: symbol,
              annual_income: annual_dividend_income,
              dividend_yield: dividend_yield || 0.0
            }

            total_portfolio_dividend_yield += annual_dividend_income
          end
        rescue Provider::Error => e
          Rails.logger.warn("Failed to fetch dividends for #{symbol}: #{e.message}")
          # Continue to next holding if FMP call fails
        end
      end

      overall_yield = if total_portfolio_value.positive?
                        (total_portfolio_dividend_yield.to_d / total_portfolio_value.to_d) * 100
                      else
                        0.0
                      end

      {
        dividend_forecast: dividend_forecast,
        total_annual_dividend_income: total_portfolio_dividend_yield,
        overall_portfolio_yield: overall_yield
      }
    end
  end
end
