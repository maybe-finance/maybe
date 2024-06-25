class Account::Valuation < ApplicationRecord
  include Account::Entryable

  def trend
    @trend ||= create_trend
  end

  def oldest?
    entry.account.valuations.with_entry.chronological.limit(1).first.entry.date == self.entry.date
  end

  def sync_account_later
    if destroyed?
      sync_start_date = previous_valuation&.date
    else
      sync_start_date = [ date_previously_was, date ].compact.min
    end

    account.sync_later(sync_start_date)
  end

  private

    def previous_valuation
      @previous_valuation ||= self.entry.account
                                  .valuations
                                  .with_entry
                                  .where("date < ?", self.entry.date)
                                  .order(date: :desc)
                                  .first
    end

    def create_trend
      TimeSeries::Trend.new \
        current: self.entry.amount_money,
        previous: previous_valuation&.entry&.amount_money,
        favorable_direction: self.entry.account.favorable_direction
    end
end
