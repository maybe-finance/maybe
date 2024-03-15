
class TimeSeries
    attr_reader :type

    def initialize(balances, options = {})
        @type = options[:type] || TimeSeries::Trend::TYPES[:normal]
        @balances = (balances.nil? || balances.empty?) ? [] : balances.map { |b| TimeSeries::Value.new(b) }.sort_by(&:date)
    end

    def values
        @values ||= add_trends_to_balances
    end

    def first
        values.first
    end

    def last
        values.last
    end

    def trend
        return nil if values.empty?
        TimeSeries::Trend.new(
            current: last.value,
            previous: first.value,
            type: @type
        )
    end

    # Data shape that frontend expects for D3 charts
    def to_json(*_args)
        {
            values: values.map do |v|
                {
                    date: v.date,
                    value: v.value,
                    trend: {
                        type: v.trend.type,
                        direction: v.trend.direction,
                        value: v.trend.value,
                        percent: v.trend.percent
                    }
                }
            end,
            trend: trend ? {
                type: @type,
                direction: trend.direction,
                value: trend.value,
                percent: trend.percent
            } : nil,
            type: @type
        }.to_json
    end

    private
        def add_trends_to_balances
            [ nil, *@balances ].each_cons(2).map do |previous, current|
                unless current.trend
                    current.trend = TimeSeries::Trend.new(
                        current: current.value,
                        previous: previous&.value,
                        type: @type
                    )
                end
                current
            end
        end
end
