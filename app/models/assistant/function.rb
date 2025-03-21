class Assistant::Function
  class << self
    def name
      raise NotImplementedError, "Subclasses must implement the name class method"
    end

    def description
      raise NotImplementedError, "Subclasses must implement the description class method"
    end

    def parameters
      {
        type: "object",
        properties: {},
        required: []
      }
    end
  end

  def call(params = {})
    raise NotImplementedError, "Subclasses must implement the call instance method"
  end
end
