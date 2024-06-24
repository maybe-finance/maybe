class Account::Valuation < ApplicationRecord
  include Monetizable

  monetize :value

  belongs_to :account

  validates :account, :date, :value, presence: true
  validates :date, uniqueness: { scope: :account_id }

  scope :chronological, -> { order(:date) }
  scope :reverse_chronological, -> { order(date: :desc) }

  def trend
    @trend ||= create_trend
  end

  def oldest?
    account.valuations.chronological.limit(1).pluck(:date).first == self.date
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
      @previous_valuation ||= self.account
                                .valuations
                                .where("date < ?", date)
                                .order(date: :desc)
                                  .first
    end

    def create_trend
      TimeSeries::Trend.new \
        current: self.value,
        previous: previous_valuation&.value,
        favorable_direction: account.favorable_direction
    end
end
