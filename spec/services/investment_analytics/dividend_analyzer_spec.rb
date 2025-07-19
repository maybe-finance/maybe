# spec/services/investment_analytics/dividend_analyzer_spec.rb

require 'rails_helper'
require_relative '../../../app/apps/investment_analytics/services/investment_analytics/dividend_analyzer'
require_relative '../../../app/apps/investment_analytics/services/investment_analytics/fmp_provider'
require_relative '../../../app/apps/investment_analytics/services/investment_analytics/exchange_rate_converter'

RSpec.describe InvestmentAnalytics::DividendAnalyzer do
  let(:account_currency) { 'USD' }
  let(:fmp_provider) { instance_double(InvestmentAnalytics::FmpProvider) }
  let(:portfolio_data) do
    {
      account_id: 1,
      account_name: 'Test Account',
      total_value: Money.from_amount(3400, 'USD'),
      holdings: [
        {
          id: 1,
          symbol: 'AAPL',
          shares: 10,
          current_price: Money.from_amount(170, 'USD'),
          current_value: Money.from_amount(1700, 'USD'),
          currency: 'USD',
          sector: 'Technology'
        },
        {
          id: 2,
          symbol: 'MSFT',
          shares: 5,
          current_price: Money.from_amount(300, 'USD'),
          current_value: Money.from_amount(1500, 'USD'),
          currency: 'USD',
          sector: 'Technology'
        },
        {
          id: 3,
          symbol: 'SAP',
          shares: 5,
          current_price: Money.from_amount(110, 'EUR'),
          current_value: Money.from_amount(605, 'USD'), # Converted value
          currency: 'EUR',
          sector: 'Software'
        }
      ]
    }
  end

  subject { described_class.new(portfolio_data, account_currency) }

  before do
    allow(Provider::Registry).to receive(:get_provider).with(:fmp).and_return(fmp_provider)
    allow(InvestmentAnalytics::ExchangeRateConverter).to receive(:convert) do |money_obj, target_currency|
      if money_obj.currency == target_currency
        money_obj
      elsif money_obj.currency == 'EUR' && target_currency == 'USD'
        Money.from_amount(money_obj.amount * 1.1, target_currency)
      else
        money_obj
      end
    end
  end

  describe '#analyze' do
    context 'with dividend data' do
      before do
        allow(fmp_provider).to receive(:historical_dividends).with('AAPL').and_return([
          { 'date' => 2.months.ago.to_s, 'dividend' => 0.22, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' },
          { 'date' => 5.months.ago.to_s, 'dividend' => 0.22, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' },
          { 'date' => 8.months.ago.to_s, 'dividend' => 0.22, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' },
          { 'date' => 11.months.ago.to_s, 'dividend' => 0.22, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' }
        ])
        allow(fmp_provider).to receive(:historical_dividends).with('MSFT').and_return([
          { 'date' => 1.month.ago.to_s, 'dividend' => 0.68, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' },
          { 'date' => 4.months.ago.to_s, 'dividend' => 0.68, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' },
          { 'date' => 7.months.ago.to_s, 'dividend' => 0.68, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' },
          { 'date' => 10.months.ago.to_s, 'dividend' => 0.68, 'declaredDate' => '', 'recordDate' => '', 'paymentDate' => '' }
        ])
        allow(fmp_provider).to receive(:historical_dividends).with('SAP').and_return([]) # No dividends for SAP
      end

      it 'calculates annual dividend income and yield for each holding' do
        analysis = subject.analyze
        expect(analysis[:dividend_forecast].count).to eq(2) # AAPL and MSFT

        aapl_forecast = analysis[:dividend_forecast].find { |f| f[:symbol] == 'AAPL' }
        expect(aapl_forecast[:annual_income]).to eq(Money.from_amount(0.22 * 4 * 10, 'USD')) # 0.88 * 10 shares
        expect(aapl_forecast[:dividend_yield]).to be_within(0.01).of((0.88 * 10 / 1700.0) * 100)

        msft_forecast = analysis[:dividend_forecast].find { |f| f[:symbol] == 'MSFT' }
        expect(msft_forecast[:annual_income]).to eq(Money.from_amount(0.68 * 4 * 5, 'USD')) # 2.72 * 5 shares
        expect(msft_forecast[:dividend_yield]).to be_within(0.01).of((2.72 * 5 / 1500.0) * 100)
      end

      it 'calculates overall portfolio dividend income and yield' do
        analysis = subject.analyze
        expected_total_income = Money.from_amount((0.22 * 4 * 10) + (0.68 * 4 * 5), 'USD')
        expect(analysis[:total_annual_dividend_income]).to eq(expected_total_income)

        expected_overall_yield = (expected_total_income.to_d / portfolio_data[:total_value].to_d) * 100
        expect(analysis[:overall_portfolio_yield]).to be_within(0.01).of(expected_overall_yield)
      end
    end

    context 'when FMP API call fails' do
      before do
        allow(fmp_provider).to receive(:historical_dividends).with('AAPL').and_raise(Provider::Error.new('API Limit'))
        allow(fmp_provider).to receive(:historical_dividends).with('MSFT').and_return([])
        allow(fmp_provider).to receive(:historical_dividends).with('SAP').and_return([])
      end

      it 'logs a warning and continues without failing' do
        expect(Rails.logger).to receive(:warn).with(/Failed to fetch dividends for AAPL: API Limit/)
        analysis = subject.analyze
        expect(analysis[:dividend_forecast]).to be_empty # AAPL failed, MSFT has no dividends
        expect(analysis[:total_annual_dividend_income]).to eq(Money.from_amount(0, 'USD'))
      end
    end

    context 'when no holdings have dividend data' do
      before do
        allow(fmp_provider).to receive(:historical_dividends).and_return([])
      end

      it 'returns empty dividend forecast and zero totals' do
        analysis = subject.analyze
        expect(analysis[:dividend_forecast]).to be_empty
        expect(analysis[:total_annual_dividend_income]).to eq(Money.from_amount(0, 'USD'))
        expect(analysis[:overall_portfolio_yield]).to eq(0.0)
      end
    end
  end
end
