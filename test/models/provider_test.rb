require "test_helper"
require "ostruct"

class TestProvider < Provider
  TestError = Class.new(StandardError)

  def initialize(client)
    @client = client
  end

  def fetch_data
    with_provider_response do
      @client.get("/test")
    end
  end

  def fetch_data_with_error_transformer
    with_provider_response(error_transformer: ->(error) { TestError.new(error.message) }) do
      @client.get("/test")
    end
  end
end

class ProviderTest < ActiveSupport::TestCase
  setup do
    @client = mock
    @provider = TestProvider.new(@client)
  end

  test "returns success response with data" do
    @client.expects(:get).with("/test").returns({ some: "data" })

    response = @provider.fetch_data

    assert response.success?
    assert_equal({ some: "data" }, response.data)
  end

  test "returns failed response with error" do
    @client.expects(:get).with("/test").raises(StandardError.new("some error"))

    response = @provider.fetch_data

    assert_not response.success?
    assert_equal("some error", response.error.message)
  end

  test "provider can transform error" do
    @client.expects(:get).with("/test").raises(StandardError.new("some error"))

    response = @provider.fetch_data_with_error_transformer

    assert_not response.success?
    assert_equal("some error", response.error.message)
    assert_instance_of TestProvider::TestError, response.error
  end
end
