module Assistant::Functions::Toolable
  extend ActiveSupport::Concern

  class_methods do
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
        required: [],
        additionalProperties: false
      }
    end
  end

  def call(params = {})
    raise NotImplementedError, "Subclasses must implement the call instance method"
  end

  def name
    self.class.name
  end

  def description
    self.class.description
  end

  def parameters
    self.class.parameters
  end
end
