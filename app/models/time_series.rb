
class TimeSeries
    attr_reader :type

    def self.from_collection(collection, value_method, options = {})
        data = collection.map do |obj|
            { date: obj.date, value: obj.public_send(value_method), original: obj }
        end
        new(data, options)
    end

    def initialize(data, options = {})
        @type = options[:type] || :normal
        initialize_series_data(data)
    end

    def values
        @values ||= add_trends_to_series
    end

    def first
        values.first
    end

    def last
        values.last
    end

    def on(date)
        values.find { |v| v.date == date }
    end

    def trend
        TimeSeries::Trend.new(
            current: last&.value,
            previous: first&.value,
            type: @type
        )
    end

    # Data shape that frontend expects for D3 charts
    def to_json(*_args)
        {
            values: values.map do |v|
                {
                    date: v.date,
                    value: JSON.parse(v.value.to_json),
                    trend: {
                        type: v.trend.type,
                        direction: v.trend.direction,
                        value: JSON.parse(v.trend.value.to_json),
                        percent: v.trend.percent
                    }
                }
            end,
            trend: {
                type: @type,
                direction: trend.direction,
                value: JSON.parse(trend.value.to_json),
                percent: trend.percent
            },
            type: @type
        }.to_json
    end

    private
        def initialize_series_data(data)
            @series_data = data.nil? || data.empty? ? [] : data.map { |d| TimeSeries::Value.new(d) }.sort_by(&:date)
        end

        def add_trends_to_series
            [ nil, *@series_data ].each_cons(2).map do |previous, current|
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
