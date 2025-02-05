class Family::MetricsCalculator
  def initialize(family)
    @family = family
  end

  def calculate
    calculate_net_worth
  end

  private

    def calculate_net_worth
      Rails.logger.info("Calculating net worth for family #{@family.id}")
      period = Period.last_30_days
      snapshot = @family.snapshot(period)
      net_worth_series = snapshot[:net_worth_series]

      net_worth_series.values.each do |value|
        begin
          metric = @family.metrics.find_or_initialize_by(
            kind: "net_worth",
            date: value.date
          )

          # Only save if the value has changed or it's a new record
          if metric.new_record? || metric.value != value.value.amount
            metric.value = value.value.amount
            metric.save!
          end
        rescue ActiveRecord::RecordNotUnique
          # Silently ignore duplicate records
          next
        end
      end
    end
end
