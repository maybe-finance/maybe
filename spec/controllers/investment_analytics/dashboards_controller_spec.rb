# spec/controllers/investment_analytics/dashboards_controller_spec.rb

require 'rails_helper'
require_relative '../../../app/apps/investment_analytics/controllers/investment_analytics/dashboards_controller'

RSpec.describe InvestmentAnalytics::DashboardsController, type: :controller do
  routes { Maybe::Application.routes } # Use Maybe's application routes

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, currency: 'USD') }
  let(:portfolio_data) { { account_id: account.id, total_value: Money.from_amount(1000, 'USD'), holdings: [] } }
  let(:metrics) { { total_market_value: Money.from_amount(1000, 'USD') } }
  let(:dividend_analysis) { { total_annual_dividend_income: Money.from_amount(50, 'USD') } }

  before do
    sign_in user # Assuming Maybe has a sign_in helper for Devise or similar
    allow(InvestmentAnalytics::PortfolioFetcher).to receive(:new).and_return(instance_double(InvestmentAnalytics::PortfolioFetcher, fetch: portfolio_data))
    allow(InvestmentAnalytics::MetricCalculator).to receive(:new).and_return(instance_double(InvestmentAnalytics::MetricCalculator, calculate: metrics))
    allow(InvestmentAnalytics::DividendAnalyzer).to receive(:new).and_return(instance_double(InvestmentAnalytics::DividendAnalyzer, analyze: dividend_analysis))
  end

  describe 'GET #index' do
    context 'with a specific account_id' do
      it 'assigns the correct account and fetches data' do
        get :index, params: { account_id: account.id }
        expect(assigns(:account)).to eq(account)
        expect(assigns(:portfolio_data)).to eq(portfolio_data)
        expect(assigns(:metrics)).to eq(metrics)
        expect(assigns(:dividend_analysis)).to eq(dividend_analysis)
        expect(response).to render_template(:index)
      end
    end

    context 'without an account_id' do
      let(:another_account) { create(:account, user: user, currency: 'USD') }

      before do
        # Ensure there's at least one account for the user
        allow(user).to receive(:accounts).and_return(double(ActiveRecord::Relation, find: account, first: account))
      end

      it 'defaults to the first account and fetches data' do
        get :index
        expect(assigns(:account)).to eq(account)
        expect(assigns(:portfolio_data)).to eq(portfolio_data)
        expect(assigns(:metrics)).to eq(metrics)
        expect(assigns(:dividend_analysis)).to eq(dividend_analysis)
        expect(response).to render_template(:index)
      end
    end

    context 'when no accounts are available' do
      before do
        allow(user).to receive(:accounts).and_return(double(ActiveRecord::Relation, find: nil, first: nil))
      end

      it 'assigns empty data' do
        get :index
        expect(assigns(:account)).to be_nil
        expect(assigns(:portfolio_data)).to eq({ holdings: [] })
        expect(assigns(:metrics)).to eq({})
        expect(assigns(:dividend_analysis)).to eq({})
        expect(response).to render_template(:index)
      end
    end
  end

  describe 'GET #portfolio_summary' do
    it 'renders the portfolio summary partial' do
      get :portfolio_summary, params: { account_id: account.id }
      expect(response).to render_template(partial: 'investment_analytics/dashboards/_portfolio_summary')
      expect(assigns(:account)).to eq(account)
      expect(assigns(:metrics)).to eq(metrics)
      expect(assigns(:portfolio_data)).to eq(portfolio_data)
    end
  end

  describe 'GET #dividend_forecast' do
    it 'renders the dividend forecast partial' do
      get :dividend_forecast, params: { account_id: account.id }
      expect(response).to render_template(partial: 'investment_analytics/dashboards/_dividend_forecast')
      expect(assigns(:account)).to eq(account)
      expect(assigns(:dividend_analysis)).to eq(dividend_analysis)
    end
  end
end
