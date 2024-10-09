  class ValueGroup
    attr_accessor :parent, :original
    attr_reader :name, :children, :value, :currency

    def initialize(name, currency = Money.default_currency)
      @name = name
      @currency = Money::Currency.new(currency)
      @children = []
    end

    def sum
      return value if is_value_node?
      return Money.new(0, currency) if children.empty? && value.nil?
      children.sum(&:sum)
    end

    def avg
      return value if is_value_node?
      return Money.new(0, currency) if children.empty? && value.nil?
      leaf_values = value_nodes.map(&:value)
      leaf_values.compact.sum / leaf_values.compact.size
    end

    def series
      return @series if is_value_node?

      summed_by_date = children.each_with_object(Hash.new(0)) do |child, acc|
        child.series.values.each do |series_value|
          acc[series_value.date] += series_value.value
        end
      end

      first_child = children.first

      summed_series = summed_by_date.map { |date, value| { date: date, value: value } }

      TimeSeries.new(summed_series, favorable_direction: first_child&.series&.favorable_direction || "up")
    end

    def series=(series)
      raise "Cannot set series on a non-leaf node" unless is_value_node?

      _series = series || TimeSeries.new([])

      raise "Series must be an instance of TimeSeries" unless _series.is_a?(TimeSeries)
      raise "Series must contain money values in the node's currency" unless _series.values.all? { |v| v.value.currency == currency }
      @series = _series
    end

    def value_nodes
      return [ self ] unless value.nil?
      children.flat_map { |child| child.value_nodes }
    end

    def empty?
      value_nodes.empty?
    end

    def percent_of_total
      return 100 if parent.nil? || parent.sum.zero?

      ((sum / parent.sum) * 100).round(1)
    end

    def add_child_group(name, currency = Money.default_currency)
      raise "Cannot add subgroup to node with a value" if is_value_node?
      child = self.class.new(name, currency)
      child.parent = self
      @children << child
      child
    end

    def add_value_node(original, value, series = nil)
      raise "Cannot add value node to a non-leaf node" unless can_add_value_node?
      child = self.class.new(original.name)
      child.original = original
      child.value = value
      child.series = series
      child.parent = self
      @children << child
      child
    end

    def value=(value)
      raise "Cannot set value on a non-leaf node" unless is_leaf_node?
      raise "Value must be an instance of Money" unless value.is_a?(Money)
      @value = value
      @currency = value.currency
    end

    def is_leaf_node?
      children.empty?
    end

    def is_value_node?
      value.present?
    end

    private
      def can_add_value_node?
        return false if is_value_node?
        children.empty? || children.all?(&:is_value_node?)
      end
  end
