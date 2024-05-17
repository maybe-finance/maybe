require "test_helper"

class UpgradeTest < ActiveSupport::TestCase
  setup do
    data = {
      commit_sha: "latestcommit",
      version: Semver.new("0.1.0-alpha.2")
    }

    @commit_upgrade = Upgrader::Upgrade.new "commit", data
    @release_upgrade = Upgrader::Upgrade.new "release", data
  end

  test "available if latest commit and app not upgraded" do
    Maybe.stubs(:version).returns(@commit_upgrade.version)
    Maybe.stubs(:commit_sha).returns("outdatedcommitsha")

    assert @commit_upgrade.available?
    assert_not @release_upgrade.available?
  end

  test "available if latest release and app not upgraded" do
    Maybe.stubs(:version).returns(Semver.new("0.1.0-alpha.1"))
    Maybe.stubs(:commit_sha).returns("outdatedcommitsha")

    assert @commit_upgrade.available?
    assert @release_upgrade.available?
  end

  test "not available if app commit greater or equal to" do
    Maybe.stubs(:version).returns(@commit_upgrade.version)
    Maybe.stubs(:commit_sha).returns(@commit_upgrade.commit_sha)

    assert_not @commit_upgrade.available?
  end
end
