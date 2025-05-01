class Provider::Stripe::EventProcessor
  def initialize(event:, client:)
    @event = event
    @client = client
  end

  def process
    raise NotImplementedError, "Subclasses must implement the process method"
  end

  private
    attr_reader :event, :client

    def event_data
      event.data.object
    end
end
