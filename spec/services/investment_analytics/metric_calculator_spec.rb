# spec/services/investment_analytics/metric_calculator_spec.rb

require 'rails_helper'
require_relative '../../../app/apps/investment_analytics/services/investment_analytics/metric_calculator'

RSpec.describe InvestmentAnalytics::MetricCalculator do
  let(:account_currency) { 'USD' }
  let(:portfolio_data) do
    {
      account_id: 1,
      account_name: 'Test Account',
      holdings: [
        {
          id: 1,
          symbol: 'AAPL',
          shares: 10,
          cost_basis: Money.from_amount(1500, 'USD'),
          current_price: Money.from_amount(170, 'USD'),
          current_value: Money.from_amount(1700, 'USD'),
          currency: 'USD',
          sector: 'Technology'
        },
        {
          id: 2,
          symbol: 'GOOG',
          shares: 5,
          cost_basis: Money.from_amount(1000, 'USD'),
          current_price: Money.from_amount(220, 'USD'),
          current_value: Money.from_amount(1100, 'USD'),
          currency: 'USD',
          sector: 'Technology'
        },
        {
          id: 3,
          symbol: 'SAP',
          shares: 5,
          cost_basis: Money.from_amount(500, 'EUR'), # Cost basis in EUR
          current_price: Money.from_amount(110, 'EUR'), # Price in EUR
          current_value: Money.from_amount(605, 'USD'), # Converted value in USD (5 * 110 * 1.1)
          currency: 'EUR',
          sector: 'Software'
        }
      ]
    }
  end

  subject { described_class.new(portfolio_data, account_currency) }

  before do
    # Stub the ExchangeRateConverter for consistent testing
    allow(InvestmentAnalytics::ExchangeRateConverter).to receive(:convert) do |money_obj, target_currency|
      if money_obj.currency == target_currency
        money_obj
      elsif money_obj.currency == 'EUR' && target_currency == 'USD'
        Money.from_amount(money_obj.amount * 1.1, target_currency)
      else
        money_obj # Fallback for other currencies
      end
    end
  end

  describe '#calculate' do
    it 'calculates total market value correctly' do
      metrics = subject.calculate
      expected_total_market_value = Money.from_amount(1700 + 1100 + 605, 'USD')
      expect(metrics[:total_market_value]).to eq(expected_total_market_value)
    end

    it 'calculates total cost basis correctly' do
      metrics = subject.calculate
      # Assuming cost_basis in portfolio_data is already in account_currency
      expected_total_cost_basis = Money.from_amount(1500 + 1000 + 500, 'USD')
      expect(metrics[:total_cost_basis]).to eq(expected_total_cost_basis)
    end

    it 'calculates total gain/loss correctly' do
      metrics = subject.calculate
      # (1700 - 1500) + (1100 - 1000) + (605 - 500)
      expected_total_gain_loss = Money.from_amount(200 + 100 + 105, 'USD')
      expect(metrics[:total_gain_loss]).to eq(expected_total_gain_loss)
    end

    it 'calculates total day-over-day change (placeholder)' do
      metrics = subject.calculate
      expect(metrics[:total_day_change]).to eq(Money.from_amount(0, 'USD'))
    end

    context 'when holdings have missing data' do
      let(:portfolio_data) do
        {
          account_id: 1,
          account_name: 'Test Account',
          holdings: [
            {
              id: 1,
              symbol: 'AAPL',
              shares: 10,
              cost_basis: nil, # Missing cost basis
              current_price: Money.from_amount(170, 'USD'),
              current_value: Money.from_amount(1700, 'USD'),
              currency: 'USD',
              sector: 'Technology'
            }
          ]
        }
      end

      it 'handles missing cost basis gracefully' do
        metrics = subject.calculate
        expect(metrics[:total_cost_basis]).to eq(Money.from_amount(0, 'USD'))
        expect(metrics[:total_gain_loss]).to eq(Money.from_amount(0, 'USD'))
      end
    end
  end
end
