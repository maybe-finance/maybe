require "test_helper"

module GitRepositoryProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "git repository provider interface" do
    assert_respond_to @subject, :fetch_latest_upgrade_candidates
  end

  test "git repository provider response contract" do
    VCR.use_cassette "git_repository_provider/fetch_latest_upgrade_candidates" do
      response = @subject.fetch_latest_upgrade_candidates

      assert_valid_upgrade_candidate(response[:release])
      assert_valid_upgrade_candidate(response[:commit])
    end
  end

  private
    def assert_valid_upgrade_candidate(candidate)
      assert_equal Semver, candidate[:version].class
      assert_match URI::DEFAULT_PARSER.make_regexp, candidate[:url]
      assert_match(/\A[0-9a-f]{40}\z/, candidate[:commit_sha])
    end
end
