  class ValueGroup
    attr_accessor :parent
    attr_reader :name, :children, :value, :original

    def initialize(name = "Root", value: nil, original: nil)
        @name = name
        @value = value
        @children = []
        @original = original
    end

    def sum
        return value if is_value_node?
        return 0 if children.empty? && value.nil?
        children.sum(&:sum)
    end

    def avg
        return value if is_value_node?
        return 0 if children.empty? && value.nil?
        leaf_values = value_nodes.map(&:value)
        leaf_values.compact.sum.to_f / leaf_values.compact.size
    end

    def series
        return @raw_series if is_value_node?
        return nil if children.empty? || children.none? { |child| child.series.present? }
        summed_by_date = children.each_with_object(Hash.new(0)) do |child, acc|
            next unless child.series
            child.series.values.each do |series_value|
                acc[series_value.date] += series_value.value
            end
        end

        summed_series = summed_by_date.map { |date, value| { date: date, value: value } }
        TimeSeries.new(summed_series)
    end

    def value_nodes
        return [ self ] unless value.nil?
        children.flat_map { |child| child.value_nodes }
    end

    def percent_of_total
        return 1 if parent.nil?
        sum / parent.sum
    end

    def leaf?
        children.empty?
    end

    def add_child_node(name)
        raise "Cannot add subgroup to node with a value" if is_value_node?
        child = self.class.new(name)
        child.parent = self
        @children << child
        child
    end

    def add_value_node(obj)
        raise "Cannot add value node to a non-leaf node" unless can_add_value_node?
        child = create_value_node(obj)
        child.parent = self
        @children << child
        child
    end

    def attach_series(raw_series)
        validate_attached_series(raw_series)
        @raw_series = raw_series
    end

    def is_value_node?
        value.present?
    end

    private
        def can_add_value_node?
            return false if is_value_node?
            children.empty? || children.all?(&:is_value_node?)
        end

        def create_value_node(obj)
            value = if obj.respond_to?(:value)
                obj.value
            elsif obj.respond_to?(:balance)
                obj.balance
            elsif obj.respond_to?(:amount)
                obj.amount
            else
                raise ArgumentError, "Object must have a value, balance, or amount"
            end

            self.class.new(obj.name, value: value, original: obj)
        end

        def validate_attached_series(series)
            raise "Cannot add series to a node without a value" unless is_value_node?
            raise "Attached series must be a TimeSeries" unless series.is_a?(TimeSeries)
            raise "Attached series final value must match value node value" unless series.last.value == value
        end
  end
