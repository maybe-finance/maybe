# app/apps/investment_analytics/services/investment_analytics/exchange_rate_converter.rb

module InvestmentAnalytics
  class ExchangeRateConverter
    # This is a placeholder for a more robust currency conversion.
    # In a real Maybe application, you would likely leverage an existing
    # ExchangeRate::Converter or similar service provided by the core.
    # For now, it performs a direct Money.exchange_to, assuming exchange rates
    # are already loaded into the Money gem's exchange bank.
    
    def self.convert(amount_money, target_currency)
      return amount_money if amount_money.currency == target_currency

      begin
        amount_money.exchange_to(target_currency)
      rescue Money::Bank::UnknownRate # Or other specific Money errors
        Rails.logger.warn("InvestmentAnalytics: Unknown exchange rate for #{amount_money.currency} to #{target_currency}. Returning original amount.")
        amount_money # Return original if conversion fails
      end
    end
  end
end
