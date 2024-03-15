class TimeSeries::Value
    include Comparable

    attr_accessor :trend
    attr_reader :value, :date

    def initialize(obj)
        normalize_input(obj)
        validate_input
    end

    def <=>(other)
        result = date <=> other.date
        result = value <=> other.value if result == 0
        result
    end

    private
        # Accept hash or object so we can pass raw query results or model instances
        def normalize_input(obj)
            if obj.is_a?(Hash)
                @trend = obj[:trend] if obj.key?(:trend)
                @date = normalize_date(obj[:date]) if obj.key?(:date)
                value_key = obj.key?(:value) ? :value : obj.key?(:amount) ? :amount : :balance
                @value = obj[value_key] if obj.key?(value_key)
            else
                @trend = obj.trend if obj.respond_to?(:trend)
                @date = normalize_date(obj.date) if obj.respond_to?(:date)
                value_method = obj.respond_to?(:value) ? :value : obj.respond_to?(:amount) ? :amount : :balance
                @value = obj.send(value_method) if obj.respond_to?(value_method)
            end
        end

        def normalize_date(date)
          return date if date.is_a?(Date)
          return date.to_date if date.respond_to?(:to_date)
          Date.iso8601(date)
        rescue ArgumentError
          raise ArgumentError, "Invalid date"
        end

        def validate_input
            raise ArgumentError, "Date is required" unless @date.is_a?(Date)
            raise ArgumentError, "Value is required" unless @value
        end
end
