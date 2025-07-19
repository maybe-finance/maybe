# app/apps/investment_analytics/controllers/investment_analytics/dashboards_controller.rb

module InvestmentAnalytics
  class DashboardsController < InvestmentAnalytics::ApplicationController
    def index
      @account = current_user.accounts.find(params[:account_id]) if params[:account_id].present?
      @account ||= current_user.accounts.first # Default to first account if none specified

      if @account
        @portfolio_data = InvestmentAnalytics::PortfolioFetcher.new(@account).fetch
        @metrics = InvestmentAnalytics::MetricCalculator.new(@portfolio_data, @account.currency).calculate
        @dividend_analysis = InvestmentAnalytics::DividendAnalyzer.new(@portfolio_data, @account.currency).analyze
      else
        @portfolio_data = { holdings: [] }
        @metrics = {}
        @dividend_analysis = {}
      end
    end

    def portfolio_summary
      @account = current_user.accounts.find(params[:account_id])
      @portfolio_data = InvestmentAnalytics::PortfolioFetcher.new(@account).fetch
      @metrics = InvestmentAnalytics::MetricCalculator.new(@portfolio_data, @account.currency).calculate

      render partial: 'investment_analytics/dashboards/portfolio_summary', locals: { account: @account, metrics: @metrics, portfolio_data: @portfolio_data }
    end

    def dividend_forecast
      @account = current_user.accounts.find(params[:account_id])
      @portfolio_data = InvestmentAnalytics::PortfolioFetcher.new(@account).fetch
      @dividend_analysis = InvestmentAnalytics::DividendAnalyzer.new(@portfolio_data, @account.currency).analyze

      render partial: 'investment_analytics/dashboards/dividend_forecast', locals: { account: @account, dividend_analysis: @dividend_analysis }
    end
  end
end
