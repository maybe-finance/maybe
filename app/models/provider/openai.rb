class Provider::OpenAI
  def initialize(access_token)
    @client = OpenAI::Client.new(access_token: @access_token)
  end

  def responses(params = {})
    client.responses(parameters: params)
  end
end
