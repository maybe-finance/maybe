require "test_helper"

class Security::SyncerTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @provider = mock
  end

  test "syncs missing securities from provider" do
    # TODO
  end

  test "syncs diff when some securities already exist" do
    # TODO
  end

  test "no provider calls when all securities exist" do
    # TODO
  end

  test "full upsert if clear_cache is true" do
    # TODO
  end
end
