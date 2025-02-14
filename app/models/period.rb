class Period
  include ActiveModel::Validations

  attr_reader :start_date, :end_date

  validates :start_date, :end_date, presence: true
  validate :must_be_valid_date_range

  PERIODS = {
    "last_day" => {
      date_range: [ 1.day.ago.to_date, Date.current ],
      label_short: "1D",
      label: "Last Day",
      comparison_label: "vs. yesterday"
    },
    "current_week" => {
      date_range: [ Date.current.beginning_of_week, Date.current ],
      label_short: "1W",
      label: "Current Week",
      comparison_label: "vs. start of week"
    },
    "last_7_days" => {
      date_range: [ 7.days.ago.to_date, Date.current ],
      label_short: "7D",
      label: "Last 7 Days",
      comparison_label: "vs. last week"
    },
    "current_month" => {
      date_range: [ Date.current.beginning_of_month, Date.current ],
      label_short: "1M",
      label: "Current Month",
      comparison_label: "vs. start of month"
    },
    "last_30_days" => {
      date_range: [ 30.days.ago.to_date, Date.current ],
      label_short: "30D",
      label: "Last 30 Days",
      comparison_label: "vs. last month"
    },
    "last_90_days" => {
      date_range: [ 90.days.ago.to_date, Date.current ],
      label_short: "90D",
      label: "Last 90 Days",
      comparison_label: "vs. last quarter"
    },
    "current_year" => {
      date_range: [ Date.current.beginning_of_year, Date.current ],
      label_short: "1Y",
      label: "Current Year",
      comparison_label: "vs. start of year"
    },
    "last_365_days" => {
      date_range: [ 365.days.ago.to_date, Date.current ],
      label_short: "365D",
      label: "Last 365 Days",
      comparison_label: "vs. 1 year ago"
    },
    "last_5_years" => {
      date_range: [ 5.years.ago.to_date, Date.current ],
      label_short: "5Y",
      label: "Last 5 Years",
      comparison_label: "vs. 5 years ago"
    }
  }

  class << self
    def default
      from_key("last_30_days")
    end

    def from_key(key, fallback: false)
      if PERIODS[key].present?
        start_date, end_date = PERIODS[key].fetch(:date_range)
        new(start_date: start_date, end_date: end_date)
      else
        return default if fallback
        raise ArgumentError, "Invalid period key: #{key}"
      end
    end

    def all
      PERIODS.map { |key, period| from_key(key) }
    end
  end

  PERIODS.each do |key, period|
    define_singleton_method(key) do
      start_date, end_date = period.fetch(:date_range)
      new(start_date: start_date, end_date: end_date)
    end
  end

  def initialize(start_date:, end_date:, date_format: "%b %d, %Y")
    @start_date = start_date
    @end_date = end_date
    @date_format = date_format
    validate!
  end

  def date_range
    start_date..end_date
  end

  def key
    PERIODS.find { |_, period| period.fetch(:date_range) == [ start_date, end_date ] }&.first
  end

  def label
    if known?
      PERIODS[key].fetch(:label)
    else
      "Custom Period"
    end
  end

  def label_short
    if known?
      PERIODS[key].fetch(:label_short)
    else
      "CP"
    end
  end

  def comparison_label
    if known?
      PERIODS[key].fetch(:comparison_label)
    else
      "#{start_date.strftime(@date_format)} to #{end_date.strftime(@date_format)}"
    end
  end

  private
    def known?
      key.present?
    end

    def must_be_valid_date_range
      return if start_date.nil? || end_date.nil?
      unless start_date.is_a?(Date) && end_date.is_a?(Date)
        errors.add(:start_date, "must be a valid date")
        errors.add(:end_date, "must be a valid date")
        return
      end

      errors.add(:start_date, "must be before end date") if start_date >= end_date
    end
end
