# spec/jobs/investment_analytics/sync_job_spec.rb

require 'rails_helper'
require_relative '../../../app/apps/investment_analytics/jobs/investment_analytics/sync_job'
require_relative '../../../app/apps/investment_analytics/services/investment_analytics/fmp_provider'

RSpec.describe InvestmentAnalytics::SyncJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:account1) { create(:account, user: user, active: true) }
  let(:account2) { create(:account, user: user, active: true) }
  let(:security_a) { create(:security, ticker: 'SYM_A', currency: 'USD') }
  let(:security_b) { create(:security, ticker: 'SYM_B', currency: 'USD') }
  let!(:holding1) { create(:holding, account: account1, security: security_a, shares: 10) }
  let!(:holding2) { create(:holding, account: account2, security: security_b, shares: 5) }

  let(:fmp_provider) { instance_double(InvestmentAnalytics::FmpProvider) }

  before do
    allow(Provider::Registry).to receive(:get_provider).with(:fmp).and_return(fmp_provider)
    allow(fmp_provider).to receive(:historical_prices).and_return([])
    allow(fmp_provider).to receive(:historical_dividends).and_return([])
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:debug)
  end

  describe '#perform' do
    it 'processes all active accounts with holdings if no account_id is given' do
      expect(fmp_provider).to receive(:historical_prices).with('SYM_A').and_return([])
      expect(fmp_provider).to receive(:historical_dividends).with('SYM_A').and_return([])
      expect(fmp_provider).to receive(:historical_prices).with('SYM_B').and_return([])
      expect(fmp_provider).to receive(:historical_dividends).with('SYM_B').and_return([])

      InvestmentAnalytics::SyncJob.perform_now

      expect(Rails.logger).to have_received(:info).with(/Syncing data for account/).twice
      expect(Rails.logger).to have_received(:info).with("InvestmentAnalytics: Sync job completed.").once
    end

    it 'only processes the specified account if account_id is given' do
      expect(fmp_provider).to receive(:historical_prices).with('SYM_A').and_return([])
      expect(fmp_provider).to receive(:historical_dividends).with('SYM_A').and_return([])
      expect(fmp_provider).not_to receive(:historical_prices).with('SYM_B')

      InvestmentAnalytics::SyncJob.perform_now(account_id: account1.id)

      expect(Rails.logger).to have_received(:info).with(/Syncing data for account #{account1.id}/).once
      expect(Rails.logger).to have_received(:info).with("InvestmentAnalytics: Sync job completed.").once
    end

    context 'when FMP API calls succeed' do
      let(:prices_data) { [{ 'date' => '2023-01-01', 'close' => 100.0, 'currency' => 'USD' }] }
      let(:dividends_data) { [{ 'date' => '2023-02-01', 'dividend' => 0.5, 'currency' => 'USD' }] }

      before do
        allow(fmp_provider).to receive(:historical_prices).with('SYM_A').and_return(prices_data)
        allow(fmp_provider).to receive(:historical_dividends).with('SYM_A').and_return(dividends_data)
      end

      it 'logs debug messages for price and dividend updates' do
        InvestmentAnalytics::SyncJob.perform_now(account_id: account1.id)
        expect(Rails.logger).to have_received(:debug).with(/Updating price for SYM_A on 2023-01-01/)
        expect(Rails.logger).to have_received(:debug).with(/Updating dividend for SYM_A on 2023-02-01/)
      end

      # Add more specific tests here if you implement actual Price/Dividend model creation/updates
    end

    context 'when FMP API call for prices fails' do
      before do
        allow(fmp_provider).to receive(:historical_prices).with('SYM_A').and_raise(Provider::Error.new('FMP Price Error'))
      end

      it 'logs an error and continues processing other data' do
        InvestmentAnalytics::SyncJob.perform_now(account_id: account1.id)
        expect(Rails.logger).to have_received(:error).with(/FMP API error for SYM_A in account #{account1.id}: FMP Price Error/)
        expect(Rails.logger).to have_received(:info).with("InvestmentAnalytics: Sync job completed.").once
      end
    end

    context 'when FMP API call for dividends fails' do
      before do
        allow(fmp_provider).to receive(:historical_dividends).with('SYM_A').and_raise(Provider::Error.new('FMP Dividend Error'))
      end

      it 'logs an error and continues processing other data' do
        InvestmentAnalytics::SyncJob.perform_now(account_id: account1.id)
        expect(Rails.logger).to have_received(:error).with(/FMP API error for SYM_A in account #{account1.id}: FMP Dividend Error/)
        expect(Rails.logger).to have_received(:info).with("InvestmentAnalytics: Sync job completed.").once
      end
    end

    context 'when FMP Provider is not registered' do
      before do
        allow(Provider::Registry).to receive(:get_provider).with(:fmp).and_return(nil)
      end

      it 'raises an error' do
        expect { InvestmentAnalytics::SyncJob.perform_now }.
          to raise_error(RuntimeError, "FMP Provider not registered")
      end
    end
  end
end
