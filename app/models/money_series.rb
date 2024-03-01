class MoneySeries
    def initialize(series, options = {})
        @trend_type = options[:trend_type] || :asset # Defines whether a positive trend is good or bad
        @accessor = options[:amount_accessor] || :balance
        @series = series
    end

    def valid?
        @series.length > 1
    end

    def data
        [ nil, *@series ].each_cons(2).map do |previous, current|
            {
                raw: current,
                date: current.date,
                value: Money.from_amount(current.send(@accessor), current.currency),
                trend: Trend.new(
                    current: current.send(@accessor),
                    previous: previous&.send(@accessor),
                    type: @trend_type
                )
            }
        end
    end

    def trend
        Trend.new(
            current: @series.last.send(@accessor),
            previous: @series.first.send(@accessor),
            type: @trend_type
        )
    end

    def serialize_for_d3_chart
        {
            data: data.map do |datum|
                {
                    date: datum[:date],
                    amount: datum[:value].amount,
                    currency: datum[:value].currency,
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
