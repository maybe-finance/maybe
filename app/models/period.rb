class Period
  attr_reader :name, :date_range

  class << self
    def from_param(param)
      find_by_name(param) || self.last_30_days
    end

    def find_by_name(name)
      INDEX[name]
    end

    def names
      INDEX.keys.sort
    end
  end

  def initialize(name: "custom", date_range:)
    @name = name
    @date_range = date_range
  end

  def extend_backward(duration)
    Period.new(name: name + "_extended", date_range: (date_range.first - duration)..date_range.last)
  end

  BUILTIN = [
    new(name: "all", date_range: nil..Date.current),
    new(name: "current_week", date_range: Date.current.beginning_of_week..Date.current),
    new(name: "last_7_days", date_range: 7.days.ago.to_date..Date.current),
    new(name: "current_month", date_range: Date.current.beginning_of_month..Date.current),
    new(name: "last_30_days", date_range: 30.days.ago.to_date..Date.current),
    new(name: "current_quarter", date_range: Date.current.beginning_of_quarter..Date.current),
    new(name: "last_90_days", date_range: 90.days.ago.to_date..Date.current),
    new(name: "current_year", date_range: Date.current.beginning_of_year..Date.current),
    new(name: "last_365_days", date_range: 365.days.ago.to_date..Date.current)
  ]

  INDEX = BUILTIN.index_by(&:name)

  BUILTIN.each do |period|
    define_singleton_method(period.name) do
      period
    end
  end
end
