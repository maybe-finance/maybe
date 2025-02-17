class IncomeStatement
  attr_reader :family, :period

  def initialize(family, period: Period.last_30_days)
    @family = family
    @period = period
  end
end
