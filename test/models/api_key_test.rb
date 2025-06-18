require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  def setup
    @user = users(:family_admin)
    # Clean up any existing API keys for this user to ensure tests start fresh
    @user.api_keys.destroy_all
    @api_key = ApiKey.new(
      user: @user,
      name: "Test API Key",
      key: "test_plain_key_123",
      scopes: [ "read_write" ]
    )
  end

  test "should be valid with valid attributes" do
    assert @api_key.valid?
  end

  test "should require display_key presence after save" do
    @api_key.key = nil
    assert_not @api_key.valid?
  end

  test "should require name presence" do
    @api_key.name = nil
    assert_not @api_key.valid?
    assert_includes @api_key.errors[:name], "can't be blank"
  end

  test "should require scopes presence" do
    @api_key.scopes = nil
    assert_not @api_key.valid?
    assert_includes @api_key.errors[:scopes], "can't be blank"
  end

  test "should require user association" do
    @api_key.user = nil
    assert_not @api_key.valid?
    assert_includes @api_key.errors[:user], "must exist"
  end

  test "should set display_key from key before saving" do
    original_key = @api_key.key
    @api_key.save!

    # display_key should be encrypted but plain_key should return the original
    assert_equal original_key, @api_key.plain_key
  end

  test "should find api key by plain value" do
    plain_key = @api_key.key
    @api_key.save!

    found_key = ApiKey.find_by_value(plain_key)
    assert_equal @api_key, found_key
  end

  test "should return nil when finding by invalid value" do
    @api_key.save!

    found_key = ApiKey.find_by_value("invalid_key")
    assert_nil found_key
  end

  test "should return nil when finding by nil value" do
    @api_key.save!

    found_key = ApiKey.find_by_value(nil)
    assert_nil found_key
  end

  test "key_matches? should work with plain key" do
    plain_key = @api_key.key
    @api_key.save!

    assert @api_key.key_matches?(plain_key)
    assert_not @api_key.key_matches?("wrong_key")
  end

  test "should be active when not revoked and not expired" do
    @api_key.save!

    assert @api_key.active?
  end

  test "should not be active when revoked" do
    @api_key.save!
    @api_key.revoke!

    assert_not @api_key.active?
    assert @api_key.revoked?
  end

  test "should not be active when expired" do
    @api_key.expires_at = 1.day.ago
    @api_key.save!

    assert_not @api_key.active?
    assert @api_key.expired?
  end

  test "should be active when expires_at is in the future" do
    @api_key.expires_at = 1.day.from_now
    @api_key.save!

    assert @api_key.active?
    assert_not @api_key.expired?
  end

  test "should be active when expires_at is nil" do
    @api_key.expires_at = nil
    @api_key.save!

    assert @api_key.active?
    assert_not @api_key.expired?
  end

  test "should generate secure key" do
    key = ApiKey.generate_secure_key

    assert_kind_of String, key
    assert_equal 64, key.length  # hex(32) = 64 characters
    assert key.match?(/\A[0-9a-f]+\z/)  # only hex characters
  end

  test "should update last_used_at when update_last_used! is called" do
    @api_key.save!
    original_time = @api_key.last_used_at

    sleep(0.01)  # Ensure time difference
    @api_key.update_last_used!

    assert_not_equal original_time, @api_key.last_used_at
    assert @api_key.last_used_at > (original_time || Time.at(0))
  end

  test "should prevent user from having multiple active api keys" do
    @api_key.save!

    second_key = ApiKey.new(
      user: @user,
      name: "Second API Key",
      key: "another_key_123",
      scopes: [ "read" ]
    )

    assert_not second_key.valid?
    assert_includes second_key.errors[:user], "can only have one active API key per source (web)"
  end

  test "should allow user to have new active key after revoking old one" do
    @api_key.save!
    @api_key.revoke!

    second_key = ApiKey.new(
      user: @user,
      name: "Second API Key",
      key: "another_key_123",
      scopes: [ "read" ]
    )

    assert second_key.valid?
  end

  test "should include active api keys in active scope" do
    @api_key.save!
    active_keys = ApiKey.active

    assert_includes active_keys, @api_key
  end

  test "should exclude revoked api keys from active scope" do
    @api_key.save!
    @api_key.revoke!
    active_keys = ApiKey.active

    assert_not_includes active_keys, @api_key
  end

  test "should exclude expired api keys from active scope" do
    @api_key.expires_at = 1.day.ago
    @api_key.save!
    active_keys = ApiKey.active

    assert_not_includes active_keys, @api_key
  end

  test "should return plain_key for display" do
    original_key = @api_key.key
    @api_key.save!

    assert_equal original_key, @api_key.plain_key
  end

  test "should not allow multiple scopes" do
    @api_key.scopes = [ "read", "read_write" ]
    assert_not @api_key.valid?
    assert_includes @api_key.errors[:scopes], "can only have one permission level"
  end

  test "should validate scope values" do
    @api_key.scopes = [ "invalid_scope" ]
    assert_not @api_key.valid?
    assert_includes @api_key.errors[:scopes], "must be either 'read' or 'read_write'"
  end
end
