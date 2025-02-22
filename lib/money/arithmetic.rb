module Money::Arithmetic
  CoercedNumeric = Struct.new(:value)

  def +(other)
    if other.is_a?(Money)
      self.class.new(amount + other.amount, currency)
    else
      value = other.is_a?(CoercedNumeric) ? other.value : other
      self.class.new(amount + value, currency)
    end
  end

  def -(other)
    if other.is_a?(Money)
      self.class.new(amount - other.amount, currency)
    else
      value = other.is_a?(CoercedNumeric) ? other.value : other
      self.class.new(amount - value, currency)
    end
  end

  def -@
    self.class.new(-amount, currency)
  end

  def *(other)
    raise TypeError, "Can't multiply Money by Money, use Numeric instead" if other.is_a?(self.class)
    value = other.is_a?(CoercedNumeric) ? other.value : other
    self.class.new(amount * value, currency)
  end

  def /(other)
    if other.is_a?(self.class)
      amount / other.amount
    else
      raise TypeError, "can't divide Numeric by Money" if other.is_a?(CoercedNumeric)
      self.class.new(amount / other, currency)
    end
  end

  def abs
    self.class.new(amount.abs, currency)
  end

  def zero?
    amount.zero?
  end

  def negative?
    amount.negative?
  end

  def positive?
    amount.positive?
  end

  def to_f
    amount.to_f
  end

  # Override Ruby's coerce method so the order of operands doesn't matter
  # Wrap in Coerced so we can distinguish between Money and other types
  def coerce(other)
    [ self, CoercedNumeric.new(other) ]
  end
end
