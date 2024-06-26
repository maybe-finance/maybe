class Account::Valuation < ApplicationRecord
  include Account::Entryable

  def trend
    @trend ||= create_trend
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
