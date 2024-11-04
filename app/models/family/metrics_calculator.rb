class Family::MetricsCalculator
  def initialize(family)
    @family = family
  end

  def calculate
    calculate_net_worth
  end

  private

    def calculate_net_worth
      period = Period.last_30_days
      snapshot = @family.snapshot(period)
      net_worth_series = snapshot[:net_worth_series]

      net_worth_series.values.each do |value|
        @family.metrics.find_or_initialize_by(
          kind: "net_worth",
          date: value.date
        ).update!(value: value.value.amount)
      end
    end
end
