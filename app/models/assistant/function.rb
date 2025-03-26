class Assistant::Function
  Error = Class.new(StandardError)
  Response = Data.define(:success?, :data, :error)

  class << self
    def name
      raise NotImplementedError, "Subclasses must implement the name class method"
    end

    def description
      raise NotImplementedError, "Subclasses must implement the description class method"
    end
  end

  def initialize(user)
    @user = user
  end

  def call(params = {})
    raise NotImplementedError, "Subclasses must implement the call method"
  end

  def name
    self.class.name
  end

  def description
    self.class.description
  end

  def params_schema
    build_schema
  end

  # (preferred) when in strict mode, the schema needs to include all properties in required array
  def strict_mode?
    true
  end

  private
    attr_reader :user

    def build_schema(properties: {}, required: [])
      {
        type: "object",
        properties: properties,
        required: required,
        additionalProperties: false
      }
    end

    def family_account_names
      @family_account_names ||= family.accounts.active.pluck(:name)
    end

    def family_category_names
      @family_category_names ||= begin
        names = family.categories.pluck(:name)
        names << "Uncategorized"
        names
      end
    end

    def family_merchant_names
      @family_merchant_names ||= family.merchants.pluck(:name)
    end

    def family_tag_names
      @family_tag_names ||= family.tags.pluck(:name)
    end

    def family
      user.family
    end
end
