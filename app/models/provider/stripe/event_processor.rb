class Provider::Stripe::EventProcessor
  def initialize(event)
    @event = event
  end

  def process
    raise NotImplementedError, "Subclasses must implement the process method"
  end

  private
    attr_reader :event

    def event_data
      event.data.object
    end
end
