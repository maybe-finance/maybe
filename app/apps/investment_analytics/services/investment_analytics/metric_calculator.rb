# app/apps/investment_analytics/services/investment_analytics/metric_calculator.rb

require_relative './exchange_rate_converter'

module InvestmentAnalytics
  class MetricCalculator
    def initialize(portfolio_data, account_currency)
      @portfolio_data = portfolio_data
      @account_currency = account_currency
    end

    def calculate
      total_market_value = Money.from_amount(0, @account_currency)
      total_cost_basis = Money.from_amount(0, @account_currency)
      total_gain_loss = Money.from_amount(0, @account_currency)
      total_day_change = Money.from_amount(0, @account_currency)

      @portfolio_data[:holdings].each do |holding|
        # Ensure all amounts are Money objects in their original currency
        current_price_money = Money.from_amount(holding[:current_price], holding[:currency]) if holding[:current_price]
        cost_basis_money = Money.from_amount(holding[:cost_basis], @account_currency) if holding[:cost_basis]

        # Convert current_price to account currency using the new converter
        converted_current_price_money = if current_price_money
                                          InvestmentAnalytics::ExchangeRateConverter.convert(
                                            current_price_money,
                                            @account_currency
                                          )
                                        else
                                          nil
                                        end

        # Calculate current value in account currency
        current_value_money = if converted_current_price_money && holding[:shares]
                                converted_current_price_money * holding[:shares]
                              else
                                Money.from_amount(0, @account_currency)
                              end

        # Accumulate totals
        total_market_value += current_value_money
        total_cost_basis += cost_basis_money if cost_basis_money

        # Calculate gain/loss for this holding
        if current_value_money.present? && cost_basis_money.present?
          holding_gain_loss = current_value_money - cost_basis_money
          total_gain_loss += holding_gain_loss
        end

        # Day-over-day change (requires historical data, placeholder for now)
        # This would typically involve fetching yesterday's price and comparing
        # For simplicity, we'll assume 0 for now or a placeholder if not available
        holding[:day_change] = Money.from_amount(0, @account_currency) # Placeholder
        total_day_change += holding[:day_change]
      end

      {
        total_market_value: total_market_value,
        total_cost_basis: total_cost_basis,
        total_gain_loss: total_gain_loss,
        total_day_change: total_day_change,
        # Add other metrics as needed
      }
    end
  end
end
