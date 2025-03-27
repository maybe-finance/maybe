# A stream proxy for OpenAI chat responses
#
# - Consumes an OpenAI chat response stream
# - Outputs a generic "Chat Provider Stream" interface to consumers (e.g. `Assistant`)
class Provider::Openai::ChatStreamer
  def initialize(output_stream)
    @output_stream = output_stream
  end

  def call(chunk)
    @output_stream.call(chunk)
  end
end
