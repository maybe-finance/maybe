require "test_helper"

class UpgraderTest < ActiveSupport::TestCase
  PRIOR_COMMIT = "47bb430954292d2fdcc81082af731a16b9587da2"
  CURRENT_COMMIT = "47bb430954292d2fdcc81082af731a16b9587da3"
  NEXT_COMMIT = "47bb430954292d2fdcc81082af731a16b9587da4"

  PRIOR_VERSION = Semver.new("0.1.0-alpha.3")
  CURRENT_VERSION = Semver.new("0.1.0-alpha.4")
  NEXT_VERSION = Semver.new("0.1.0-alpha.5")

  # Default setup assumes app is up to date
  setup do
    Upgrader.config = Upgrader::Config.new({ mode: :enabled })

    Maybe.stubs(:version).returns(CURRENT_VERSION)
    Maybe.stubs(:commit_sha).returns(CURRENT_COMMIT)

    stub_github_data(
      commit: create_upgrade_stub(CURRENT_VERSION, CURRENT_COMMIT),
      release: create_upgrade_stub(CURRENT_VERSION, CURRENT_COMMIT)
    )
  end

  test "finds 1 completed upgrade, 0 available upgrades when app is up to date" do
    assert_instance_of Upgrader::Upgrade, Upgrader.completed_upgrade
    assert_nil Upgrader.available_upgrade
  end

  test "finds 1 available upgrade when app is on latest release but behind latest commit" do
    stub_github_data(
      commit: create_upgrade_stub(CURRENT_VERSION, NEXT_COMMIT),
      release: create_upgrade_stub(CURRENT_VERSION, CURRENT_COMMIT)
    )

    assert_instance_of Upgrader::Upgrade, Upgrader.available_upgrade # commit is ahead of release
    assert_instance_of Upgrader::Upgrade, Upgrader.completed_upgrade # release is completed
  end

  test "when app is behind latest version and latest commit is ahead of release finds release upgrade and no completed upgrades" do
    Maybe.stubs(:version).returns(PRIOR_VERSION)
    Maybe.stubs(:commit_sha).returns(PRIOR_COMMIT)

    stub_github_data(
      commit: create_upgrade_stub(CURRENT_VERSION, NEXT_COMMIT),
      release: create_upgrade_stub(CURRENT_VERSION, CURRENT_COMMIT)
    )

    assert_equal "release", Upgrader.available_upgrade.type
    assert_nil Upgrader.completed_upgrade
  end

  test "defaults to app version when no release is found" do
    stub_github_data(
      commit: create_upgrade_stub(CURRENT_VERSION, NEXT_COMMIT),
      release: nil
    )

    # Upstream is 1 commit ahead, and we assume we're on the same release
    assert_equal "commit", Upgrader.available_upgrade.type
  end

  test "gracefully handles empty github info" do
    Provider::Github.any_instance.stubs(:fetch_latest_upgrade_candidates).returns(nil)

    assert_nil Upgrader.available_upgrade
    assert_nil Upgrader.completed_upgrade
  end

  test "deployer is null by default" do
    Upgrader.config = Upgrader::Config.new({ mode: :enabled })
    Upgrader::Deployer::Null.any_instance.expects(:deploy).with(nil).once
    Upgrader.upgrade_to(nil)
  end

  private
    def create_upgrade_stub(version, commit_sha)
      {
        version: version,
        commit_sha: commit_sha,
        url: ""
      }
    end

    def stub_github_data(commit: create_upgrade_stub(LATEST_VERSION, LATEST_COMMIT), release: create_upgrade_stub(LATEST_VERSION, LATEST_COMMIT))
      Provider::Github.any_instance.stubs(:fetch_latest_upgrade_candidates).returns({ commit:, release: })
    end
end
