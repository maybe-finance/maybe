class TimeSeries::Value
    include Comparable

    attr_accessor :trend
    attr_reader :value, :date, :original

    def initialize(obj)
        @original = obj.fetch(:original, obj)

        if obj.is_a?(Hash)
            @date = obj[:date]
            @value = obj[:value]
        else
            @date = obj.date
            @value = obj.value
        end

        validate_input
    end

    def <=>(other)
        result = date <=> other.date
        result = value <=> other.value if result == 0
        result
    end

    private
        def validate_input
            raise ArgumentError, "Date is required" unless @date.is_a?(Date)
            raise ArgumentError, "Money or Numeric value is required" unless @value.is_a?(Money) || @value.is_a?(Numeric)
        end
end
