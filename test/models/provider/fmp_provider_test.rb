require "test_helper"
require "ostruct"

class InvestmentAnalytics::FmpProviderTest < ActiveSupport::TestCase
  setup do
    @provider = InvestmentAnalytics::FmpProvider.new(api_key: "test")
  end

  test "quote returns parsed data" do
    response = OpenStruct.new(success?: true, body: [{ price: 10 }.to_json])
    HTTParty.expects(:get).returns(response)

    result = @provider.quote("AAPL")
    assert_equal({"price" => 10}, result)
  end

  test "error responses raise provider error" do
    response = OpenStruct.new(success?: false, code: 404, body: "not found")
    assert_raises(Provider::Error) { @provider.send(:handle_response, response) }
  end
end

