class MoneySeries
    def initialize(series, options = {})
        @trend_type = options[:trend_type] || "asset" # Defines whether a positive trend is good or bad
        @accessor = options[:amount_accessor] || :balance
        @fallback = options[:fallback]
        @series = series
    end

    def valid?
        @series.length > 1
    end

    def data
        series_data = [ nil, *@series ].each_cons(2).map do |previous, current|
            {
                raw: current,
                date: current.date,
                value: Money.new(current.send(@accessor), current.currency),
                trend: Trend.new(
                    current: current.send(@accessor),
                    previous: previous&.send(@accessor),
                    type: @trend_type
                )
            }
        end

        if series_data.empty? && @fallback
            series_data = [ { date: Date.current, value: @fallback, trend: Trend.new(current: 0, type: @trend_type) } ]
        end

        series_data
    end

    def last
        data.last[:value]
    end

    def trend
        return Trend.new(current: 0, type: @trend_type) unless valid?

        Trend.new(
            current: @series.last.send(@accessor),
            previous: @series.first&.send(@accessor),
            type: @trend_type
        )
    end

    def serialize_for_d3_chart
        {
            data: data.map do |datum|
                {
                    date: datum[:date],
                    amount: datum[:value].amount,
                    currency: datum[:value].currency.iso_code,
                    trend: {
                        amount: datum[:trend].amount,
                        percent: datum[:trend].percent,
                        direction: datum[:trend].direction,
                        type: datum[:trend].type
                    }
                }
            end,
            trend: {
                amount: trend.amount,
                percent: trend.percent,
                direction: trend.direction,
                type: trend.type
            }
        }.to_json
    end
end
