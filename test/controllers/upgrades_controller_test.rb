require "test_helper"

class UpgradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)

    @completed_upgrade = Upgrader::Upgrade.new(
      "commit",
      commit_sha: "47bb430954292d2fdcc81082af731a16b9587da3",
      version: Semver.new("0.0.0"),
      url: ""
    )

    @completed_upgrade.stubs(:complete?).returns(true)
    @completed_upgrade.stubs(:available?).returns(false)

    @available_upgrade = Upgrader::Upgrade.new(
      "commit",
      commit_sha: "47bb430954292d2fdcc81082af731a16b9587da4",
      version: Semver.new("0.1.0"),
      url: ""
    )

    @available_upgrade.stubs(:available?).returns(true)
    @available_upgrade.stubs(:complete?).returns(false)
  end

  test "controller not available when upgrades are disabled" do
    MOCK_COMMIT = "47bb430954292d2fdcc81082af731a16b9587da3"

    post acknowledge_upgrade_url(MOCK_COMMIT)
    assert_response :not_found

    post deploy_upgrade_url(MOCK_COMMIT)
    assert_response :not_found
  end

  test "should acknowledge an upgrade prompt" do
    with_env_overrides UPGRADES_ENABLED: "true" do
      Upgrader.stubs(:find_upgrade).returns(@available_upgrade)

      post acknowledge_upgrade_url(@available_upgrade.commit_sha)

      @user.reload
      assert_equal @user.last_prompted_upgrade_commit_sha, @available_upgrade.commit_sha
      assert :redirect
    end
  end

  test "should acknowledge an upgrade alert" do
    with_env_overrides UPGRADES_ENABLED: "true" do
      Upgrader.stubs(:find_upgrade).returns(@completed_upgrade)

      post acknowledge_upgrade_url(@completed_upgrade.commit_sha)

      @user.reload
      assert_equal @user.last_alerted_upgrade_commit_sha, @completed_upgrade.commit_sha
      assert :redirect
    end
  end

  test "should deploy an upgrade" do
    with_env_overrides UPGRADES_ENABLED: "true" do
      Upgrader.stubs(:find_upgrade).returns(@available_upgrade)

      post deploy_upgrade_path(@available_upgrade.commit_sha)

      @user.reload
      assert_equal @user.last_prompted_upgrade_commit_sha, @available_upgrade.commit_sha
      assert :redirect
    end
  end

  test "should rollback user state if upgrade fails" do
    with_env_overrides UPGRADES_ENABLED: "true" do
      PRIOR_COMMIT = "47bb430954292d2fdcc81082af731a16b9587da2"
      @user.update!(last_prompted_upgrade_commit_sha: PRIOR_COMMIT)

      Upgrader.stubs(:find_upgrade).returns(@available_upgrade)
      Upgrader.stubs(:upgrade_to).returns({ success: false })

      post deploy_upgrade_path(@available_upgrade.commit_sha)

      @user.reload
      assert_equal @user.last_prompted_upgrade_commit_sha, PRIOR_COMMIT
      assert :redirect
    end
  end
end
