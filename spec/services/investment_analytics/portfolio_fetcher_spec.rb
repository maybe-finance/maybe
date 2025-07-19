# spec/services/investment_analytics/portfolio_fetcher_spec.rb

require 'rails_helper'
require_relative '../../../app/apps/investment_analytics/services/investment_analytics/portfolio_fetcher'
require_relative '../../../app/apps/investment_analytics/services/investment_analytics/exchange_rate_converter'

RSpec.describe InvestmentAnalytics::PortfolioFetcher do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, currency: 'USD') }
  let(:security_usd) { create(:security, ticker: 'AAPL', name: 'Apple Inc.', currency: 'USD', sector: 'Technology') }
  let(:security_eur) { create(:security, ticker: 'SAP', name: 'SAP SE', currency: 'EUR', sector: 'Software') }
  let!(:holding_usd) { create(:holding, account: account, security: security_usd, shares: 10, cost_basis: 1500) }
  let!(:holding_eur) { create(:holding, account: account, security: security_eur, shares: 5, cost_basis: 500) }
  let!(:price_usd) { create(:price, security: security_usd, date: Time.zone.today, amount: 170.00, currency: 'USD') }
  let!(:price_eur) { create(:price, security: security_eur, date: Time.zone.today, amount: 110.00, currency: 'EUR') }

  subject { described_class.new(account) }

  before do
    # Stub the ExchangeRateConverter for consistent testing
    allow(InvestmentAnalytics::ExchangeRateConverter).to receive(:convert) do |money_obj, target_currency|
      if money_obj.currency == target_currency
        money_obj
      elsif money_obj.currency == 'EUR' && target_currency == 'USD'
        # Assume a fixed exchange rate for testing purposes (e.g., 1 EUR = 1.1 USD)
        Money.from_amount(money_obj.amount * 1.1, target_currency)
      else
        money_obj # Fallback for other currencies
      end
    end
  end

  describe '#fetch' do
    it 'returns structured portfolio data for the account' do
      portfolio_data = subject.fetch

      expect(portfolio_data).to be_a(Hash)
      expect(portfolio_data[:account_id]).to eq(account.id)
      expect(portfolio_data[:account_name]).to eq(account.name)
      expect(portfolio_data[:holdings]).to be_an(Array)
      expect(portfolio_data[:holdings].count).to eq(2)

      # Test USD holding
      usd_holding_data = portfolio_data[:holdings].find { |h| h[:symbol] == 'AAPL' }
      expect(usd_holding_data).to be_present
      expect(usd_holding_data[:shares]).to eq(10)
      expect(usd_holding_data[:current_price]).to eq(Money.from_amount(170.00, 'USD'))
      expect(usd_holding_data[:current_value]).to eq(Money.from_amount(1700.00, 'USD'))
      expect(usd_holding_data[:currency]).to eq('USD')
      expect(usd_holding_data[:sector]).to eq('Technology')

      # Test EUR holding (converted to USD)
      eur_holding_data = portfolio_data[:holdings].find { |h| h[:symbol] == 'SAP' }
      expect(eur_holding_data).to be_present
      expect(eur_holding_data[:shares]).to eq(5)
      expect(eur_holding_data[:current_price]).to eq(Money.from_amount(110.00, 'EUR')) # Original price currency
      expect(eur_holding_data[:current_value]).to eq(Money.from_amount(5 * 110.00 * 1.1, 'USD')) # Converted value
      expect(eur_holding_data[:currency]).to eq('EUR') # Original holding currency
      expect(eur_holding_data[:sector]).to eq('Software')

      # Test total value (sum of converted values)
      expected_total_value = Money.from_amount(1700.00 + (5 * 110.00 * 1.1), 'USD')
      expect(portfolio_data[:total_value]).to eq(expected_total_value)
    end

    context 'when a holding has no price data' do
      let!(:holding_no_price) { create(:holding, account: account, security: create(:security, ticker: 'NO_PRICE', currency: 'USD'), shares: 5, cost_basis: 100) }

      it 'excludes the holding from calculations if current_value is nil' do
        portfolio_data = subject.fetch
        expect(portfolio_data[:holdings].map { |h| h[:symbol] }).not_to include('NO_PRICE')
      end
    end
  end
end
