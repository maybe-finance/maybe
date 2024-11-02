require "test_helper"

class Issue::ExchangeRateProviderMissingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @issue = issues(:one)
  end

  test "should update issue" do
    patch issue_exchange_rate_provider_missing_url(@issue), params: {
      issue_exchange_rate_provider_missing: {
        synth_api_key: "1234"
      }
    }

    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to @issue.issuable.accountable
  end
end
