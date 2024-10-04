class Gapfiller
  attr_reader :series

  def initialize(series, start_date:, end_date:, cache:)
    @series = series
    @date_range = start_date..end_date
    @cache = cache
  end

  def run
    gapfilled_records = []

    date_range.each do |date|
      record = @series.find { |r| r.date == date }

      if should_gapfill?(date, record)
        prev_record = gapfilled_records.last || @series.find { |r| r.date < date }&.last

        if prev_record
          new_record = create_gapfilled_record(prev_record, date)
          gapfilled_records << new_record
        end
      else
        gapfilled_records << record if record
      end
    end

    gapfilled_records
  end

  private
    attr_reader :date_range, :cache

    def should_gapfill?(date, record)
      record.nil? || date.on_weekend?
    end

    def create_gapfilled_record(prev_record, date)
      new_record = prev_record.class.new(prev_record.attributes.except("id", "created_at", "updated_at"))
      new_record.date = date
      new_record.save! if cache
      new_record
    end
end
