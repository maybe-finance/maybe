require "test_helper"
require "ostruct"

class TestProvider < Provider
  def fetch_data
    with_provider_response(retries: 3) do
      client.get("/test")
    end
  end

  private
    def client
      @client ||= Faraday.new
    end

    def retryable_errors
      [ Faraday::TimeoutError ]
    end
end

class ProviderTest < ActiveSupport::TestCase
  setup do
    @provider = TestProvider.new
  end

  test "retries then provides failed response" do
    client = mock
    Faraday.stubs(:new).returns(client)

    client.expects(:get)
          .with("/test")
          .raises(Faraday::TimeoutError)
          .times(3)

    response = @provider.fetch_data

    assert_not response.success?
    assert_match "timeout", response.error.message
  end

  test "fail, retry, succeed" do
    client = mock
    Faraday.stubs(:new).returns(client)

    sequence = sequence("retry_sequence")

    client.expects(:get)
          .with("/test")
          .raises(Faraday::TimeoutError)
          .in_sequence(sequence)

    client.expects(:get)
          .with("/test")
          .returns(Provider::Response.new(success?: true, data: "success", error: nil))
          .in_sequence(sequence)

    response = @provider.fetch_data

    assert response.success?
  end
end
